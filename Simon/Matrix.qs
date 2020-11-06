
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

	open Microsoft.Quantum.ModularArithmetic.DebugHelpers;
  open Quantum.BlockCipherBasics;

  // # Summary
  // Wrapper for qubits representing a binary matrix
  // of a given width and height
  newtype BinQMatrix = (entries: Qubit[][], height : Int, width : Int);

  // # Summary
  // Returns a random matrix with {0,1} entries
  // of the specified size and width
  operation RandomMatrix(height : Int, width : Int) : Int[][] {
    mutable matrix = new Int[][height];
    for (idx in 0..height - 1){
      mutable row = new Int[width];
      for (idy in 0..width - 1){
        set row w/= idy <- Microsoft.Quantum.Random.DrawRandomInt(0, 1);
      }
      set matrix w/= idx <- row;
    }
    return matrix;
  }

  // # Summary
  // Writes a classical matrix, as a two-dimensional integer array,
  // onto a quantum matrix. 
  //
  // # Inputs
  // ## cMatrix
  // Classical matrix. All entires must be {0,1}, and dimensions must
  // match the quantum matrix
  // ## qMatrix
  // Qubit matrix
  operation WriteQMatrix(cMatrix : Int[][], qMatrix : BinQMatrix) : Unit {
    body (...){
      // todo: check that heights match
      for (idx in 0..qMatrix::height - 1){
        for (idy in 0..qMatrix::width - 1){
          if (cMatrix[idx][idy] == 1){
            X(qMatrix::entries[idx][idy]);
          }
        }
      }
    }
    controlled adjoint auto;
  }

  // # Summary
  // Measures a quantum matrix, setting all qubits to 0,
  // and returns the result as a {0,1} two-dimensional
  // integer array.
  operation MeasureQMatrix(qMatrix : BinQMatrix) : Int[][] {
    body (...){
      mutable matrix = new Int[][qMatrix::height];
      for (idx in 0..qMatrix::height - 1){
        mutable row = new Int[qMatrix::width];
        for (idy in 0..qMatrix::width - 1){
          if (M(qMatrix::entries[idx][idy]) == One){
            set row w/= idy <- 1;

          } else {
            set row w/= idy <- 0;
          }
        }
        set matrix w/= idx <- row;
        ResetAll(qMatrix::entries[idx]);
      }
      return matrix;
    }
  }

  // # Summary
  // Finds the rank of a classical {0,1} matrix
  // over F2
  function ClassicalMatrixRank(matrix : Int[][]) : Int {
    mutable reducedMatrix = matrix;
    mutable rank = 0;
    let height = Length(matrix);
    let width = Length(matrix[0]);
    for (idx in 0..height - 1){
      mutable idy = 0;
      while (idy < width and reducedMatrix[idx][idy] == 0){
        set idy = idy + 1;
      }
      if (idy < width){
        set rank = rank + 1;
        for (idz in idx + 1..height - 1){
          if (reducedMatrix[idz][idy] == 1){
            mutable newRow = new Int[width];
            for (idw in 0 .. width - 1){
              set newRow w/= idw <- (reducedMatrix[idx][idw] + reducedMatrix[idz][idw]) % 2;
            }
            set reducedMatrix w/= idz <- newRow;
          }
        }
      }
    }
    return rank;
  }

  // # Summary
  // Checks if two matrices are equal
  // Returns false if they are not the same size.
  function MatrixEquality(matrix1 : Int[][], matrix2 : Int[][]) : Bool {
    if (Length(matrix1) != Length(matrix2)){
      return false;
    }
    for (idx in 0.. Length(matrix1) - 1){
      if (Length(matrix1[idx]) != Length(matrix2[idx])) {
        return false;
      }
      for (idy in 0.. Length(matrix1[idx]) - 1){
        if (matrix1[idx][idy] != matrix2[idx][idy]){
          return false;
        }
      }
    }
    return true;
  }

 
  // # Summary
  // Debugging tool which outputs a quantum matrix as 
  // a string of 0s and 1s, but preserves the state
  operation DumpMatrix(matrix : BinQMatrix, message : String) : Unit {
    body (...){
      Message(message);
      for (idx in 0 .. matrix::height - 1) {
        DumpQubits(matrix::entries[idx], "");
      }
    }
    adjoint (...){
      Message(message);
      for (idx in 0..matrix::height - 1){
        DumpQubits(matrix::entries[idx], "");
      }
    }
    controlled adjoint auto;
  }

  // # Summary
  // Given a wrapper for a qubit matrix, returns a wrapper
  // for the transpose. The resulting object references
  // the same qubits, but treats them as the transpose
  function TransposeMatrix(matrix : BinQMatrix) : BinQMatrix {
    mutable newEntries = new Qubit[][matrix::width];
    for (idx in 0..matrix::width - 1){
      mutable newRow = new Qubit[matrix::height];
      for (idy in 0..matrix::height - 1){
        set newRow w/= idy <- matrix::entries[idy][idx];
      }
      set newEntries w/= idx <- newRow;
    }
    return BinQMatrix(newEntries, matrix::width, matrix::height);
  }


  // # Summary
  // Given an array of qubits, formats them into a quantum matrix object
  // of a specified height and width.
  function QubitArrayAsMatrix(height : Int, width : Int, entries : Qubit[]) : BinQMatrix {
    Fact(Length(entries)==height*width, $"Requires {height*width} qubits, given only {Length(entries)}");
    return BinQMatrix(Microsoft.Quantum.Arrays.Chunks(width, entries), height, width);
  }


  // # Summary
  // The same function as `TriangularBasis` but uses Controlled BitWiseXor
  // Because of an issue in Q# this is needlessly inefficient
  // and, until this issue is fixed, it is better to manage the qubits manually
  // See: https://github.com/microsoft/qsharp-runtime/issues/419
  operation TriangularBasisSlow(matrix : BinQMatrix, bs : Qubit[], avs : Qubit[], useds : Qubit[]) : Unit {
    body(...){
      let bIndices = TriangularIndices(matrix::width);
      for (idy in 0..matrix::width - 1){
        for (idx in 0..matrix::height - 1){
          CCNOT(matrix::entries[idx][idy], avs[idy], useds[idx]);
          CCNOT(matrix::entries[idx][idy], useds[idx], avs[idy]);
          if (idy < matrix::width - 1){
            (Controlled BitWiseXor)([useds[idx]], (matrix::entries[idx][idy+1..matrix::width -1], bs[bIndices[idy] .. bIndices[idy + 1] - 1]));
            (Controlled BitWiseXor)([matrix::entries[idx][idy]], (bs[bIndices[idy] .. bIndices[idy + 1] - 1], matrix::entries[idx][idy+1..matrix::width -1]));
          }
        }
      }
    }
    controlled adjoint auto;
  }

  // # Summary 
  // Triangularizes a quantum binary matrix, such that after completion, the qubits `avs` 
  // will be all zero if and only if the matrix is full rank
  //
  // # Inputs
  // ## matrix
  // A binary quantum matrix
  // ## bs
  // Qubits initialized to 0 which are the "basis" vectors obtained.
  // Must contain at least width*(width-1)/2 qubits
  // ## avs
  // Qubits initialized to 1. Must have at least "width" qubits
  // ## useds
  // Qubits initialized to 0, must have at least "height" qubits
  operation TriangularBasis(matrix : BinQMatrix, bs : Qubit[], avs : Qubit[], useds : Qubit[]) : Unit {
    body(...){
      let bIndices = TriangularIndices(matrix::width);
      using ((spareUsedControls, spareXControls) = (Qubit[Length(bs)], Qubit[Length(bs)])) {
        for (idy in 0..matrix::width - 1){
          for (idx in 0..matrix::height - 1){
            CCNOT(matrix::entries[idx][idy], avs[idy], useds[idx]);
            CCNOT(matrix::entries[idx][idy], useds[idx], avs[idy]);
            if (idy < matrix::width - 1){
              // fanout controls
              let usedControls = spareUsedControls[bIndices[idy]..bIndices[idy+1] - 1];
              let xControls = spareXControls[bIndices[idy]..bIndices[idy+1] - 1];
              let bOutputs = bs[bIndices[idy] .. bIndices[idy + 1] - 1];
              FanoutToZero(useds[idx], usedControls);
              for (idz in 0.. matrix::width - idy - 2) {
                 CCNOT(usedControls[idz], matrix::entries[idx][idy + 1 + idz], bOutputs[idz]);
              }
              (Adjoint FanoutToZero)(useds[idx], usedControls);
              FanoutToZero(matrix::entries[idx][idy], xControls);
              for (idz in 0..matrix::width - idy - 2){
                CCNOT(xControls[idz], bOutputs[idz], matrix::entries[idx][idy+1+idz]);
              }
              (Adjoint FanoutToZero)(matrix::entries[idx][idy], xControls);
            }
          }
        }
      }
    }
    controlled adjoint auto;
  }

  // # Summary
  // Given a height of a matrix, we want to reshape a 1-dimensional
  // array of qubits into a triangular array of qubits of the form
  // * * * * * *
  // * * * * *
  // * * * *
  // * * *
  // * *
  // (e.g., for height = 7). This returns an integer array
  // where the ith entry is the index in the original array
  // where the qubits in the ith row will start
  function TriangularIndices(height : Int) : Int[] {
    mutable indices = new Int[height];
      for (idx in 1 .. height - 1){
        set indices w/= idx <- indices[idx-1] + height - idx;
      }
    return indices;
  }

  // # Summary
  // Flips a check qubit if a quantum matrix is full rank; does nothing otherwise.
  operation IsFullRank(matrix : BinQMatrix, check : Qubit) : Unit {
    body (...) {
      (Controlled IsFullRank)(new Qubit[0], (matrix, check));
    }
    controlled (controls, ...){
      if (matrix::width > matrix::height){
        (Controlled IsFullRank)(controls, (TransposeMatrix(matrix), check));
      } else {
         using (bs = Qubit[(matrix::width * (matrix::width - 1))/2]){
          using (avs = Qubit[(matrix::width)]){
            ApplyToEachCA(X, avs);
            using (useds = Qubit[matrix::height]){
              TriangularBasis(matrix, bs, avs, useds);
              (Controlled CheckIfAllZero)(controls, (avs, check));
              (Adjoint TriangularBasis)(matrix, bs, avs, useds);
            }
            (Adjoint ApplyToEachCA)(X, avs);
          }
        }
      }
    }
  }

  
}