x3: fastqCollapse
	./fastqCollapse -i ../../example/input_files/example.1.fq.gz ../../example/input_files/example.2.fq.gz -o test -summary summary.txt

clean:
	rm fastqCollapse

fastqCollapse: fastqCollapse.cpp
	g++ fastqCollapse.cpp -static -o fastqCollapse -lz
