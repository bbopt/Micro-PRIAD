## Black-Box Parameters (ARGS.txt)

The fifferent argument given to Micro-PRIAD are listed here. to initialize a parameter use the option in the command line `-param value` to set param to value. The complete documentation of the argument is done in the appendix of the Micro-PRIAD GERAD paper. Lines in the example (i) and (ii) can be used as command-line option by adding a `-` before the line.

The different arguments that Micro-PRIAD can take as input can be provided through the `ARGS.txt` file. The parameters are listed and described below. A simple example of an `ARGS.txt` file is available in this directory [(i)](/Micro-PRIAD/Documentation/BB_Parameter/ex_ARGS.txt), and a fully documented ARGS.txt is available in the tests directory [(ii)](/Micro-PRIAD/Tests/instance=1/ex_ARGS.txt).

---

### Parameters List

  * **`PG`**: A character that can take the values `[s, r, u, t]` to select a specific Power Grid (PG) to simulate. An optimization problem is defined by the PG and the lengt of the input (x). It does not change the number of constraints or affect the input vector in the case of `[s, r, u]`, but the PG `t` set the length of the input vector to 4 and has no constraint. 
  * *Default value:* `s`

  * **`N`**: Explicitly fixes the maximum number of Monte Carlo trials, which represents the ground-truth benchmark accuracy.
  * *Default value:* `10000`

* **`s`**: Controls the size of the group evaluated between each subsample and intermediate output.
  * *Default value:* `1000`

  * **`eta`**: Controls the number of group of size `s` evluated to complete an evaluation.
  * *Default value:* `10`

* **`seed`**: An integer representing the random seed used for the Monte Carlo trials. Changing the seed will cause Micro-PRIAD to return different results due to varying random trial sequences. By giving a seed of -1 to Micro-PRIAD, the value of the seed will be set at random.
  * *Default value:* `0`

### Advance Paraleters List

* **`availInterrupter`**: A boolean flag allowing additional intermediate returns at critical points when not all constraints are being evaluated with the same number of MC draws. The respective number of MC draws used to average the constraint values are tracked via an internal vector that count teh number of MC draws done to evaluated each output functions.

* **`Interrupter`**: A parameter (function) that indicate if and how intermediary ouput are handled. This function intercepts intermediate objective function values and constraint metrics at specific number of MC draws evaluated to decide whether to early-terminate the black-box iteration or let it run to completion. It is triggered frequently at various number of MC draws evaluated milestones. You must specify both the path to the `.jl` file and the specific name of the Julia function. 

  Four built-in functions are already implemented:
  * `basicInterrupter`: Always returns `true` (never interrupts the black-box execution). *--> Default value*
  * `printInterReturnInterrupter`: Logs every intermediate evaluation step into a `.txt` file and pauses, waiting for a user decision via an external file to either abort or resume the evaluation.
  * `DeterministicInfoInterrupter`: Aborts the execution (returns `false`) as soon as one of the 5 deterministic constraints is violated, saving computational overhead.
  * `feasiblePtsFinderInterrupter`: Uses central limit theorem to find a feasible solution faster than when using all N MC draws at each evaluation. 

* **`AnyParamForInterrupter`**: A string parameter passed directly to the custom `Interrupter` Julia function. Some custom functions require specific initialization strings or flags here.
  * *Default value:* `""`

  * **`SubSampler`**: A parameter (function) that indicate if and how the sub-sampling of stage one's output of the blackbox is done before giving it to the stage two of the blackbox. In the `ARGS.txt` file, you must specify both the path to the `.jl` file and the specific name of the Julia function. 
One built-in function is implemented in this version:
* `basicSubSampling`: Does not sub sample, it returns all sample. *--> Default value*

* **`AnyParamForSubSampler`**: A string parameter passed directly to the custom `SubSampler` Julia function. 
  * *Default value:* `""`

* **`loggingTime`**: A parameter used for benchmarking. If set to `"false"`, time logging is deactivated. If set to a specific file path, it will create a time-log file where each line records the exact execution time of a single evaluation.
  * *Default value:* `"false"`* 
  
* **`loggingN`**: A parameter used for benchmarking. If set to `"false"`, M.C. trials logging is deactivated. If set to a specific file path, it will create a N-log file where each line records the exact number of M.C. trials done to do a single evaluation.
  * *Default value:* `"false"`* 


### Other Paratmeters

* **`first_s_to_one`**: A parameter enables or disables a functionality that sets the size of the first group evaluated in the MC loop to one if enabled. 
  * *Default value:* `false`

* **`single_MC_info_return`**: A parameter (function) that indicates if the user wants the program to print every single Monte-Carlo trial in a .txt file. You must specify both the path to the `.jl` file and the specific name of the Julia function.

Tree built-in functions are already implemented:
* `basic_single_MC_info_return`: Does not return anything. *--> Default value*
* `print_single_MC_info_return`: Return the result of f C6 C7 C8 and C9 (stochastic objective function and constraints) in a .txt file. To use this function, `eta` must be set to 1.
* `print_single_MC_info_return_for_subSampling`: Return the result of f C8 and C9 (objective function and constraints calculated in the second stage of the blackbox)

* **`AnyParamForSingle_MC_Info_Return`**: A string parameter passed direcly to the custom `single_MC_info_return` julia function. Built-in functions use this parameter to specify a path for the logging .txt file.
* *Default value:* `""`

* **`fidelity`**: A real number bounded between `0.0` and `1.0` that represents the accuracy of the final output relative to reality. For each increment of `0.0001` in fidelity, the black-box performs one additional Monte Carlo (MC) trial, up to a maximum of 10,000 trials when fidelity is set to `1.0`. This is true if `N` is unchanged.
  * *Default value:* `1.0`
  
* **`loggingPhi`**: A parameter used for benchmarking. If set to `"false"`, Phi logging is deactivated. If set to a specific file path, it will create a Phi-log file where each line records the fidelity at witch a given evaluation was done, it take the highest fidelity among output if different.
  * *Default value:* `"false"`




> **Note:** The parameter flaged with (function) are functions that can be created by the user and given to Micro-PRIAD. For specific use of the bult-in function and their param refer to the article.

> **Note:** The parameter flaged with (PG = t supported) are parameters that the tenth instance support xxx.
--------------------------------------------

> A briefly described summary of the Micro-PRIAD needs is presented in the tests [directory](../../Tests/instance=1/ex_ARGS.txt).

--------------------------------------------

[Back to Main README](../README.md)