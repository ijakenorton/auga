// ringbuf.h - Per-function-scope arena allocator with shared page pool
//
// Drop-in replacement for arena.h. Cross-platform (libc malloc only).
//
// Key design:
//   - Each function call gets its own Arena (call_stack[call_depth] in auga.c)
//   - if/for/while blocks share the enclosing function's arena
//   - On function return, arena pages go to a global pool for reuse
//   - New arenas draw pages from the pool before calling malloc

#ifndef RINGBUF_H_
#define RINGBUF_H_

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#ifndef ARENA_ASSERT
#include <assert.h>
#define ARENA_ASSERT assert
#endif

#ifndef ARENA_REGION_DEFAULT_CAPACITY
#define ARENA_REGION_DEFAULT_CAPACITY (4*1024)
#endif

#ifndef ARENA_DA_INIT_CAP
#define ARENA_DA_INIT_CAP 256
#endif

typedef struct Region Region;
struct Region {
    Region *next;
    size_t count;      // used slots (in uintptr_t units)
    size_t capacity;   // total slots (in uintptr_t units)
    uintptr_t data[];
};

typedef struct {
    Region *begin, *end;
} Arena;

typedef struct {
    Region *region;
    size_t count;
} Arena_Mark;

#ifdef __cplusplus
    #define cast_ptr(ptr) (decltype(ptr))
#else
    #define cast_ptr(...)
#endif

#define arena_da_append(a, da, item)                                                          \
    do {                                                                                      \
        if ((da)->count >= (da)->capacity) {                                                  \
            size_t new_capacity = (da)->capacity == 0 ? ARENA_DA_INIT_CAP : (da)->capacity*2; \
            (da)->items = cast_ptr((da)->items)arena_realloc(                                 \
                (a), (da)->items,                                                             \
                (da)->capacity*sizeof(*(da)->items),                                          \
                new_capacity*sizeof(*(da)->items));                                           \
            (da)->capacity = new_capacity;                                                    \
        }                                                                                     \
        (da)->items[(da)->count++] = (item);                                                  \
    } while (0)

void *arena_alloc(Arena *a, size_t size_bytes);
void *arena_realloc(Arena *a, void *oldptr, size_t oldsz, size_t newsz);
char *arena_strdup(Arena *a, const char *cstr);
Arena_Mark arena_snapshot(Arena *a);
void arena_rewind(Arena *a, Arena_Mark m);
void arena_free(Arena *a);

// Drain the shared pool (call at program exit)
void ringbuf_drain_pool(void);

#endif // RINGBUF_H_

#ifdef RINGBUF_IMPLEMENTATION

#include <stdlib.h>

// Shared page pool - reused across all arenas
static Region *rb_pool = NULL;

static Region *rb_get_page(size_t min_size) {
    // Try pool first: find any page with enough capacity
    Region **prev = &rb_pool;
    for (Region *r = rb_pool; r != NULL; r = r->next) {
        if (r->capacity >= min_size) {
            *prev = r->next;
            r->next = NULL;
            r->count = 0;
            return r;
        }
        prev = &r->next;
    }
    // Allocate new page
    size_t capacity = ARENA_REGION_DEFAULT_CAPACITY;
    if (capacity < min_size) capacity = min_size;
    size_t size_bytes = sizeof(Region) + sizeof(uintptr_t) * capacity;
    Region *r = (Region *)malloc(size_bytes);
    ARENA_ASSERT(r);
    r->next = NULL;
    r->count = 0;
    r->capacity = capacity;
    return r;
}

static void rb_return_page(Region *r) {
    r->count = 0;
    r->next = rb_pool;
    rb_pool = r;
}

void *arena_alloc(Arena *a, size_t size_bytes) {
    size_t size = (size_bytes + sizeof(uintptr_t) - 1) / sizeof(uintptr_t);

    if (a->end == NULL) {
        ARENA_ASSERT(a->begin == NULL);
        Region *r = rb_get_page(size);
        a->begin = r;
        a->end = r;
    }

    if (a->end->count + size > a->end->capacity) {
        Region *r = rb_get_page(size);
        a->end->next = r;
        a->end = r;
    }

    void *result = &a->end->data[a->end->count];
    a->end->count += size;
    return result;
}

void *arena_realloc(Arena *a, void *oldptr, size_t oldsz, size_t newsz) {
    if (newsz <= oldsz) return oldptr;
    void *newptr = arena_alloc(a, newsz);
    if (oldptr) memcpy(newptr, oldptr, oldsz);
    return newptr;
}

char *arena_strdup(Arena *a, const char *s) {
    size_t n = strlen(s);
    char *dup = (char *)arena_alloc(a, n + 1);
    memcpy(dup, s, n + 1);
    return dup;
}

Arena_Mark arena_snapshot(Arena *a) {
    Arena_Mark m;
    if (a->end == NULL) {
        m.region = NULL;
        m.count = 0;
    } else {
        m.region = a->end;
        m.count = a->end->count;
    }
    return m;
}

void arena_rewind(Arena *a, Arena_Mark m) {
    if (m.region == NULL) {
        // Return all pages to pool
        Region *r = a->begin;
        while (r) {
            Region *next = r->next;
            rb_return_page(r);
            r = next;
        }
        a->begin = NULL;
        a->end = NULL;
        return;
    }

    // Return pages after mark to pool
    Region *r = m.region->next;
    while (r) {
        Region *next = r->next;
        rb_return_page(r);
        r = next;
    }
    m.region->next = NULL;
    m.region->count = m.count;
    a->end = m.region;
}

void arena_free(Arena *a) {
    // Return live pages to pool, then drain pool pages via free()
    Region *r = a->begin;
    while (r) {
        Region *next = r->next;
        free(r);
        r = next;
    }
    a->begin = NULL;
    a->end = NULL;
}

void ringbuf_drain_pool(void) {
    Region *r = rb_pool;
    while (r) {
        Region *next = r->next;
        free(r);
        r = next;
    }
    rb_pool = NULL;
}

#endif // RINGBUF_IMPLEMENTATION
