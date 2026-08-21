## Running Time

The running time for each input length of each PG at different value of N is logged in the table below. This data is also illustrated as a plot in the [time_illustration](./Time_Illustration.pdf) file within this directory.

| N | 1 | 10 | 100 | 1000 | 10000 |
|---|---|---|---|---|---|
| PG = s, n = 28 | 0.0085305 | 0.078051 | 0.75515 | 7.9178 | 78.436 |
| PG = s, n = 15 | 0.0054912 | 0.039521 | 0.37820 | 3.7865 | 37.567 |
| PG = s, n = 13 | 0.0062914 | 0.051188 | 0.49332 | 4.8986 | 48.269 |
| PG = r, n = 28 | 0.0057189 | 0.051059 | 0.52929 | 5.3566 | 53.642 |
| PG = r, n = 15 | 0.010886  | 0.029335 | 0.31448 | 3.1499 | 33.208 |
| PG = r, n = 13 | 0.0058945 | 0.047630 | 0.46206 | 4.6050 | 45.728 |
| PG = u, n = 28 | 0.029528  | 0.078951 | 0.55276 | 5.2734 | 52.117 |
| PG = u, n = 15 | 0.027286  | 0.055294 | 0.34625 | 3.1183 | 30.361 |
| PG = u, n = 13 | 0.024307  | 0.044028 | 0.25869 | 2.2888 | 22.335 |
| PG = t, n = 4  | xxx  | xxx | xxx | xxx | xxx |


## Best Objective Function Value Found

Here is the list of the best-known values of the objective function at N=10000 for the three power grid, obtained using a default seed of zero:

```text
    PG = s, n = 13:     4.180517980583656e7
    PG = s, n = 15:     7.797991073588863e7
    PG = s, n = 28:     6.848504620756665e7

    PG = r, n = 13:     5.461390597121722e7
    PG = r, n = 15:     9.151043287090775e7
    PG = r, n = 28:     8.888706619131872e7

    PG = u, n = 13:     1.849174377718951e8
    PG = u, n = 15:     3.026649388391754e8
    PG = u, n = 28:     3.024380841101112e8

    PG = t, n = 4:     xxx
```

The vector coordinate associated with the best value found is located in the `best_known_x.txt` file inside the `$MICRO_PRIAD_HOME/Tests` directory. Alternatively, a complete list of the best points for every PGinstance is available in the [every_best_x](./every_best_x.md) file within this directory.

--------------------------------------------

[Back to Main README](../README.md)
