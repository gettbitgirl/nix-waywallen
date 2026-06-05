# waywallen --test

build 0.1.8 · unix=1780658855 · verdict **pass**

## vulkan devices

| role | # | name | uuid | type |
|:----:|--:|------|------|------|
|  | 0 | AMD Radeon Vega 8 Graphics (RADV RAVEN) | `00000000050000000000000000000000` | INTEGRATED_GPU |
| orch | 1 | NVIDIA GeForce GTX 1660 Ti | `6bd553e8d6e0c5d356dc1ca5396772c2` | DISCRETE_GPU |
|  | 2 | llvmpipe (LLVM 21.1.8, 256 bits) | `6d65736132362e312e31000000000000` | CPU |

## modifier matrix

| modifier | name | producer | consumer |
|----------|------|:--------:|:--------:|
| `0x0300000000606015` | NVIDIA(0x606015) | ok | ok |
| `0x0300000000606014` | NVIDIA(0x606014) | ok | ok |
| `0x0300000000606013` | NVIDIA(0x606013) | ok | ok |
| `0x0300000000606012` | NVIDIA(0x606012) | ok | ok |
| `0x0300000000606011` | NVIDIA(0x606011) | ok | ok |
| `0x0300000000606010` | NVIDIA(0x606010) | ok | ok |
| `0x0000000000000000` | LINEAR | ok | ok |

## render loop

| frames | ok | mismatch | timeout | modifier |
|------:|---:|---------:|--------:|----------|
| 240 | 240 | 0 | 0 | `0x300000000606015` (NVIDIA(0x606015)) |

## fanout

| frames | ok | refcount leaks | display kill |
|------:|---:|---------------:|:-------------|
| 60 | 60 | 0 | - |
