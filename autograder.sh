#!/bin/bash

#SBATCH --job-name=mpi_results
#SBATCH --output=mpi_results.out
#SBATCH --error=mpi_results.err
#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --exclusive

# Maximum time allowed for the script (in seconds)
MAX_EXECUTION_TIME=1800

# Run the tests within the time limit
timeout $MAX_EXECUTION_TIME bash -c '

lscpu
echo "-------------------------------------"

# Run the tests
module load openmpi

make clean
make

# Correctness tests
echo " "
echo "=================== CORRECTNESS TESTS ==================="
echo " "
echo "##Scatter"
srun -n 16 ./primitives -s 100000000 5
srun -n 24 ./primitives -s 100000000 5
echo " "
echo "##AllGather"
srun -n 16 ./primitives -g 100000000 0
srun -n 24 ./primitives -g 100000000 0
echo " "
echo "##AllReduce"
srun -n 16 ./primitives -r 100000000 0
srun -n 24 ./primitives -r 100000000 0
echo " "
echo "##AlltoAll_Arbitrary"
srun -n 16 ./primitives -a 100000000 0
srun -n 24 ./primitives -a 100000000 0
echo " "
echo "##AlltoAll_Hypercube"
srun -n 16 ./primitives -h 100000000 0
echo " "


echo "==================== RUNTIME TESTS ====================="
echo " "

multiplier=25
echo "##Scatter"
output_16=$(srun -n 16 ./primitives -s 100000000 0)
echo "$output_16"
custom_16=$(echo "$output_16" | grep "Custom_" | awk "{print \$3}")
mpi_16=$(echo "$output_16" | grep "MPI_" | awk "{print \$3}")

if (( $(echo "$custom_16 < $multiplier * $mpi_16" | bc -l) )); then
    echo "Runtime test passed!"
else
    echo "Runtime test failed"
fi

echo " "
echo "##AllGather"
multiplier=3
output_16=$(srun -n 16 ./primitives -g 100000000 0)
echo "$output_16"
custom_16=$(echo "$output_16" | grep "Custom_" | awk "{print \$3}")
mpi_16=$(echo "$output_16" | grep "MPI_" | awk "{print \$3}")

if (( $(echo "$custom_16 < $multiplier * $mpi_16" | bc -l) )); then
    echo "Runtime test passed!"
else
    echo "Runtime test failed"
fi

echo " "
echo "##AllReduce"
multiplier=10
output_16=$(srun -n 16 ./primitives -r 100000000 0)
echo "$output_16"
custom_16=$(echo "$output_16" | grep "Custom_" | awk "{print \$3}")
mpi_16=$(echo "$output_16" | grep "MPI_" | awk "{print \$3}")

if (( $(echo "$custom_16 < $multiplier * $mpi_16" | bc -l) )); then
    echo "Runtime test passed!"
else
    echo "Runtime test failed"
fi

echo " "
echo "##AlltoAll_Arbitrary"
multiplier=2
output_16=$(srun -n 16 ./primitives -a 100000000 0)
echo "$output_16"
custom_16=$(echo "$output_16" | grep "Custom_" | awk "{print \$3}")
mpi_16=$(echo "$output_16" | grep "MPI_" | awk "{print \$3}")

if (( $(echo "$custom_16 < $multiplier * $mpi_16" | bc -l) )); then
    echo "Runtime test passed!"
else
    echo "Runtime test failed"
fi

echo " "
echo "##AlltoAll_Hypercube"
multiplier=10
output_16=$(srun -n 16 ./primitives -h 100000000 0)
echo "$output_16"
custom_16=$(echo "$output_16" | grep "Custom_" | awk "{print \$3}")
mpi_16=$(echo "$output_16" | grep "MPI_" | awk "{print \$3}")

if (( $(echo "$custom_16 < $multiplier * $mpi_16" | bc -l) )); then
    echo "Runtime test passed!"
else
    echo "Runtime test failed"
fi


echo " "

'

if [[ $? -eq 124 ]]; then
    echo "Error: Script execution exceeded $MAX_EXECUTION_TIME seconds."
    exit 1
fi