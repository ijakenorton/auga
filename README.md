# Auga

Early stage of Auga!

As I wanted to pay homage to Odin, Auga is in reference to eye in Nordic. Either Odins lost eye, or the knowledge he gained.
Dynamically scoped (may change to lexical, unsure), interpretted expression based language written in Odin!

### Currently implemented:
- Function decl
- Function call
- If
- Else
- Return
- Add
- Divide
- Multiply
- Same (equality)
- Print to stdout intrinsic

## Build

Currently requires installed Odin compiler. Maybe some plans to vendor in the Odin compiler into the project.

```
#clone the repo
git clone git@github.com:ijakenorton/auga.git
# or git clone https://github.com/ijakenorton/auga.git
cd auga
odin build .
```

### To run the interpreter

```
#./auga <input_file.auga>
./auga test.auga
./auga test.auga debug
# Debug flag prints out the outer mode env state, can be useful though rudimentary stage
```

