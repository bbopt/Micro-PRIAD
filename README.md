# Micro-PRIAD v1.0 (May 2026)
Micro-PRIAD is a stochastic blackbox collection of ten problems that implements the intermediate return and allows for sub-sampling of th MC draws within an evaluation. It simulates an electrical grid to evaluate the cost of a given maintenance strategy. The goal is to minimize the cost by finding an optimal feasible strategy.
## Download
To download the **Micro-PRIAD** blackbox you must have Julia 1.12 version installed on your computer. Skip the section **downloading Julia** if you already have Julia 1.12 or a newer version on your computer.
> Note : commands below work on Linux and macOS.
### Downloading Julia
You can download Julia simply by running the following command in the terminal:
```
curl -fsSL https://install.julialang.org | sh
```
You should now have Julia installed on your computer. You can verify by typing in the terminal:
```
julia
```
> **Note:** You might need to load the Julia module for future use.
### Downloading Micro-PRIAD
 Now you only need to download the folder `Micro-PRIAD`.

 To use the commands describded later, you need to initialize the environment variable  `$MICRO_PRIAD_HOME`. To create an environment variable, you need to open `~/.bashrc` by running the following command in the terminal:
```
nano ~/.bashrc
```
Then, in the opened file, you initialize the environment variable `MICRO_PRIAD_HOME`, after the first line in the opened file, by writing:
```
MICRO_PRIAD_HOME="pathToMicro-PRIAD/Micro-PRIAD"
```
Where pathToMicro-PRIAD is the directory where the folder `Micro-PRIAD` was downloaded. Save the modification and escape the document. Now, to enable the new variable, you need to run the following line in the terminal:
```
source ~/.bashrc
```
To make sure you did everything right, you can try to run the following command in the terminal:
```
julia $MICRO_PRIAD_HOME/src/run.jl -test
```

> **Note:** On Windows you need to initialize the `%MICRO_PRIAD_HOME%` and use it instead of `$MICRO_PRIAD_HOME`
## Execution
### Different ways to run Micro-PRIAD
To run a simulation, there are four options.

> Note: you can always type `julia $MICRO_PRIAD_HOME/src/run.jl -help` for execution option reminder.

#### Option 1:

Type in the terminal a command that respects the following format:
```
julia $MICRO_PRIAD_HOME/src/run.jl -@param1 value1 -@param2 value2 ... -@paramN valueN path2X/x.txt 
```
The (`@paramJ valueJ`) couple is formatted as a line in the `ARGS.txt` file, and `x.txt` contains the point to evaluate (see below for formatting of those files).

A simple example with only two parameters is given here:
```
julia $MICRO_PRIAD_HOME/src/run.jl -instance 1 -fidelity 0.001 $MICRO_PRIAD_HOME/Tests/instance=3/length_input=28/x0_feasible/1.txt 
```

#### Option 2:

Type the following command in the terminal:
```
julia $MICRO_PRIAD_HOME/src/run.jl pathToARGS/ARGS.txt pathToX/x.txt
```
Where the `ARGS.txt` contains the necessary information to call the blackbox, and `x.txt` contains the point to evaluate (see below for formatting of those files).

#### Option 3:

Simply call the MicroPRIAD Julia function directly in a Julia script if your solver is defined in Julia (don't forget to include "MicroPRIAD.jl" in your script).


### Formating (to call Micro-PRIAD)

#### ARGS

To call Micro-PRIAD, the parameter to call it can be given in the command line like explained in option 1. Those arguments are describded in [ARGS_README](./Documentation/ARGS_README.md).

The `ARGS.txt` file contains the information that you need to call Micro-PRIAD when using option 2. It contains arguments described in [ARGS_README](./Documentation/ARGS_README.md) and formatted like in the `ex_ARGS.txt` files located in each folder in `$MICRO_PRIAD_HOME/Tests`.

To call Micro-PRIAD in Julia direcly, the sam parameter can be set.

All the arguments have a default value, so you can choose to initialize only the arguments that you want, in the order you want. The other argument(s) will take their default value.
#### x.txt
The `x.txt` file contains the input vector that can take different sizes:
```
input: It is the blackbox input of 28, 15, or 13 dimensions, including integer (I) and real (R) inputs. The different inputs are defined like so:
	- 28-dimensional input: [I, R, I, R, R, I, R, I, R, I, R, I, R, I, R, I, R, I, R, I, R, I, R, I, R, I, R, R]
	- 15-dimensional input: [R, R, R, R, R, R, R, R, R, R, R, R, R, R, R]
	- 13-dimensional input: [I, R, I, R, I, R, I, R, I, R, I, R, R]
```
The `x.txt` file must contain only the numerical value of each variable separated with spaces without "[", "," or "]". The `x0_feasible` and `x0_infeasible` folders contain good examples of how to format your `x.txt` file. You will find those files if you go as deep as you can in the `$MICRO_PRIAD_HOME/Tests` directory ([input length of 28 example](./Tests/instance=1/length_input=28/x0_feasible/1.txt)).

For all integer inputs, the bounds are 1 and 9, and for all real inputs, the bounds are 0.1 and 10.0.

The path and name of this file is the last argument given in the command line when calling Micro-PRIAD with option 1 or 2.

## Micro-PRIAD's Behavior
The Running time for each input length of each instance at different fidelity is logged in the [BEHAV_README](./Documentation/BEHAV_README.md). A list of the best-known objective function values is also logged in the [BEHAV_README](./Documentation/BEHAV_README.md). 

Some benchmarking data is available in the  [BENCHMARKING_README](./BenchmarkingData/BENCHMARKING_README.md)

----------------------------

The tree structure of the repo is shown in the [TREE_STRUCT](./Documentation/TREE_STRUCT.md).
