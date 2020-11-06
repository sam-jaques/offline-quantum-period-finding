namespace Quantum.Matrix
{
    open Microsoft.Quantum.Intrinsic;
	open Microsoft.Quantum.Crypto.Basics;
	open Microsoft.Quantum.Crypto.Arithmetic;
	open Microsoft.Quantum.Crypto.ModularArithmetic;
	open Microsoft.Quantum.Crypto.EllipticCurves;
	open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
	open Microsoft.Quantum.Convert;
	open Microsoft.Quantum.Math;
	open Microsoft.Quantum.Diagnostics;
  	open Microsoft.Quantum.Arrays;


  	 operation RankTestHelper( RankChecker:((BinQMatrix, Qubit)=> Unit is Ctl), matrix : Int[][], height : Int , width : Int) : Unit {
       // Bookkeeping and qubit allocation
       using (register = Qubit[width * height+1]) {
            // Write to qubit registers
            let qMatrix = QubitArrayAsMatrix(height, width, register[0..width * height - 1]);
            let qResult = register[width * height];
            WriteQMatrix(matrix, qMatrix);
            //DumpMatrix(qMatrix, "Test matrix: ");

            //Run tests
            RankChecker(qMatrix, qResult);
 
            //Compute expected classical result
            let expected = (ClassicalMatrixRank(matrix) >= Min([width, height]));

            // Check results
            mutable actualMatrix = MeasureQMatrix(qMatrix);
            Fact(MatrixEquality(actualMatrix, matrix), $"Input: Expected {matrix}, got {actualMatrix}");
            mutable result = ResultAsBool(M(qResult));
            Reset(qResult);
            Fact(result == expected, $"Output: Expected {expected}, got {result}");

            for (numberOfControls in 1..2) { 
                using (controls = Qubit[numberOfControls]) {
                    //Write to qubit registers
                    WriteQMatrix(matrix, qMatrix);

                    // controls are |0>, no addition is computed
                    // Run test
                    (Controlled RankChecker) (controls, (qMatrix,qResult));

                    //Check results
                    set actualMatrix = MeasureQMatrix(qMatrix);
		            Fact(MatrixEquality(actualMatrix, matrix), $"Control 0: Input: Expected {matrix}, got {actualMatrix}");
		            set result = ResultAsBool(M(qResult));
                    Reset(qResult);
		            Fact(result == false, $"Control 0: Output: Expected {expected}, got {result}");

                    // Write to qubit registers
                    WriteQMatrix(matrix, qMatrix);

                    // now controls are set to |1>, addition is computed
                    ApplyToEach(X, controls);

                    // Run test
                    (Controlled RankChecker) (controls, (qMatrix, qResult));

                    // Check results
                    set actualMatrix = MeasureQMatrix(qMatrix);
		            Fact(MatrixEquality(actualMatrix, matrix), $"Control 1: Input: Expected {matrix}, got {actualMatrix}");
		            set result = ResultAsBool(M(qResult));
                    Reset(qResult);
		            Fact(result == expected, $"Control 1: Output: Expected {expected}, got {result}");

                    ResetAll(controls);
                }
            }
        }
    }

    // Wrapper to help matrix tests
    operation RankCheckRandomTestHelper( RankChecker:((BinQMatrix, Qubit)=> Unit is Ctl), height : Int, width :Int, nTests:Int):Unit {
        for (roundnum in 0..nTests-1){
            let matrix = RandomMatrix(height, width);
            RankTestHelper( RankChecker, matrix, height, width);
        }
    }

    // # Summary
    // Tests nTests random matrices with heights from 4 to 14
    // and widths within +/- 2 of the height
    @Test("ToffoliSimulator")
    operation RankTest() : Unit {
        let nTests = 20;
        for (height in 4..14){
        	for (width in height-2..height+2){
        		RankCheckRandomTestHelper( IsFullRank, height, width, nTests);
        	}
        }
    }

}