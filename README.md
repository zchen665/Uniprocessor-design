# Uniprocessor-design
HDL (verilog) uniprocessor design. Computer Architecture intro class project

processor is pipelined with 5 stages: Instruction Fetch(IF), Instruction Decoding(ID), Execution(EX), Memory Access(MA), Write back(WB).

- cpu uses perfect memory that returns in the same cycle. instruction memory and data memory are 2 independent structure in this project.
- the single path version has an entire instruction done in one clock cycle without pipeline consideration, its layout, however, is implemented with consideration of pipelined design though not necessary. 
- the pipelined version added flip flops for pipeline signals of each stage. it also deals with the data and control hazards using stalls, forwarding logic, and predict-not-taken branch prediction. each false branch will cost 3 cycles.
- direct mapped cache using four-bank memory and cache interface provided by school. mainly worked on the cache control system.
- cache spec: 16 bit address space, each cache line contains 4 blocks. 256 cache lines. each block contains 2 words.
- 2-way associate cache: basically combines 2 cache with different addressing. cache spec is the same as above. cache size doubled.
- todo: 1. cache optimization: current cache can't meet timing requirement.
        2. combine cache and cpu. current cpu uses perfect memory
