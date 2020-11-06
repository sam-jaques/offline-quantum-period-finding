
namespace Quantum.BlockCipherBasics
{
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Crypto.Basics;
  open Microsoft.Quantum.Crypto.Arithmetic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Canon;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Math;
  open Microsoft.Quantum.Diagnostics;
  open Quantum.Matrix;

  open Microsoft.Quantum.ModularArithmetic.DebugHelpers;




  // # Summary
  // Quadratic function for an S-box
  // Takes a 4-bit input (x0, x1, x2, x3)
  // Transforms it to
  // (x0, x1 + x3*x2+x1*x3, x2+x1*x3, x3)
  operation Q12 (nibble : Qubit[]) : Unit {
    body (...) { 
        CCNOT(nibble[3], nibble[1], nibble[2]);
        CCNOT(nibble[3], nibble[2], nibble[1]);
      } adjoint auto;
  }


  // # Summary
  // Quadratic function for an S-box
  // Takes a 4-bit input (x0, x1, x2, x3)
  // Transforms it to
  // (x0+x1*x3, x1 + x2*x3, x2, x3)
  operation Q294 (nibble : Qubit[]) : Unit {
    body (...) { 
        CCNOT(nibble[3],nibble[1],nibble[0]);
        CCNOT(nibble[3], nibble[2], nibble[1]);
      } adjoint auto;
  }
  

  // # Summary
  // Returns the bit-length of an integer
  function BitLength(x : Int) : Int {
    mutable length = 0;
    while (2^length <= x){
      set length = length + 1;
    }
    return length - 1;
  }

  // # Summary
  // Swaps two nibbles of qubits within a larger array
  //
  // # Inputs
  // ## index1
  // Index of the first nibble to swap
  // ## index2 
  // Index of the first nibble to swap
  // ## qNibbles
  // Qubit array with qubits to swap
  //
  // # Notes
  // Nibbles are indexed by bits, i.e., the 2nd nibble would be at
  // index 8, not 2
  operation NibbleSwap(index1 : Int, index2 : Int, qNibbles : Qubit[]): Unit {
    body(...){
      for (idx in 0..3){
        SWAP(qNibbles[4*index1+idx],qNibbles[4*index2+idx]);
      }
    }
    controlled adjoint auto;
  } 

  // # Summary
  // Applies an S-box, out-of-place, to all blocks of qubits in an array of qubits
  // Uses a QROM look-up to apply the SBox.
  // Deduces the size of words based on the size of the SBox array given
  //
  // # Inputs
  // ## SBoxArray
  // A 2^n-element array of integers from 0 to 2^n-1 acting as the S-box
  // ## inputQubits
  // Qubit array input, assumed to be a multiple of n qubits
  // ## outputQubits
  // Qubit array output, assumed to be the same length as inputQubits. Output is XORed
  // onto these qubits
  operation ApplySBoxMulti(SBoxArray : Int[], inputQubits : Qubit[], outputQubits : Qubit[]) : Unit { 
    body (...){
      let blockSize = BitLength(Length(SBoxArray));
      for (idx in 0..blockSize..Length(inputQubits) - 1){
        EqualLookup<Int>(SBoxArray, ApplyXorInPlace(_, LittleEndian(outputQubits[idx .. idx + blockSize - 1])), LittleEndian(inputQubits[idx..idx + blockSize - 1]));
      }
    }
    controlled adjoint auto;
  }

  // # Summary
  // Applies an S-box, in-place, to all nibbles of qubits in an array of qubits
  // Uses a QROM look-up to apply the SBox
  // Allocates qubits to do an S-box look-up out-of-place, then does an out-of-place
  // look-up of the inverse S-box to clear the input, then swaps.
  // 
  // # Inputs
  // ## SBoxArray
  // A 16-element array of integers from 0 to 15 acting as the S-box
  // ##SBoxInvArray
  // A 16-element array of integers that acts as the inverse S-box
  // ## inputQNibbles
  // A qubit array, a multiple of 4 qubits, that will be modified
  //
  // # Notes
  // To preserve the qubit count, this operation swaps from newly allocated qubits back to the input.
  // If this operation is controlled, this will be very inefficient, and other methods should
  // probably be used.
  operation ApplySBoxMultiInPlace(SBoxArray : Int[], SBoxInvArray : Int[], inputQNibbles : Qubit[]) : Unit {
    body (...) {
      using (spareQubits = Qubit[Length(inputQNibbles)]){
        ApplySBoxMulti(SBoxArray, inputQNibbles, spareQubits);
        ApplySBoxMulti(SBoxInvArray, spareQubits, inputQNibbles);
        ApplyToEachCA(SWAP, Microsoft.Quantum.Arrays.Zipped(inputQNibbles, spareQubits));
      }
    }
    controlled adjoint auto;
  }


  // # Summary
  // XORs the bit-value of one qubit array into another
  // This is the same as applying a CNOT from every qubit in 
  // the first to every qubit in the second; however,
  // this operation includes a fanout of controls for low depth
  //
  // # Inputs
  // ## xs
  // Qubit array that will be XORed onto the other array
  // ## ys
  // Qubit array that will contain the output
   operation BitWiseXor(xs : Qubit[], ys : Qubit[]) : Unit {
      body (...){
        ApplyToEachCA(CNOT, Microsoft.Quantum.Arrays.Zipped(xs, ys));
      }
      controlled (controls, ...){
        using (spareControls = Qubit[Length(xs)]){
          (Controlled FanoutControls)(controls, (spareControls));
          for (idx in 0..Length(xs)-1){
            CCNOT(spareControls[idx], xs[idx], ys[idx]);
          }
          (Adjoint Controlled FanoutControls)(controls, (spareControls));
        }
      }
      controlled adjoint auto;
  }


  // # Summary
  // Computes a single round of a Grover oracle for a given cipher, 
  // possibly on multiple messages, including diffusion step.
  // 
  // # Inputs
  // ## blockSize
  // The size of messages to pass to the cipher
  // ## keys
  // Qubits used as keys, considered to be the qubits on which the search is performed
  // ## message
  // An array of qubits intended to contain several messages. Must be a multiple of blockSize.
  // ## phase
  // A single qubit for the phase (e.g., should be in the |-> state)
  // ## Cipher
  // An operation taking a key as first input, a message as second input.
  // ## KeyPrep
  // Operation to prepare the key in some way. If multiple messages are encrypted with the same key,
  // this will only modify the key once for each message in the set.
  operation GroverOracle(blockSize : Int, keys : Qubit[], messages : Qubit[], phase : Qubit, Cipher : ((Qubit[], Qubit[]) => Unit is Adj), KeyPrep : (Qubit[] => Unit is Adj)) : Unit {
    body (...) {
        let messageBlocks = Microsoft.Quantum.Arrays.Chunks(blockSize, messages);
        ApplyToEachCA(H, keys);
        KeyPrep(keys);
        for (idx in 0..Length(messageBlocks) - 1){
          Cipher(keys, messageBlocks[idx]);
        }
        CheckIfAllZero(messages, phase);
        for (idx in 0..Length(messageBlocks) - 1){
          Cipher(keys, messageBlocks[idx]);
        }
        (Adjoint KeyPrep)(keys);
        ApplyToEachCA(H, keys);
        CheckIfAllZero(messages, phase);
    } adjoint auto;
  }


  // # Summary
  // Debugging tool which outputs a qubit array as a hex string
  // Note: this reverses the order compared to initializing,
  // i.e., if one writes 0x01234 into a quantum array,
  // this will print it as 4321
  operation DumpQubitsAsHex(qubits:Qubit[],message:String):Unit {
    body(...){
      mutable newmessage = message;
      for (idx in 0..4..Length(qubits)-1){
        mutable newDigit = 0;
        for (idy in 0..3){
          if (idy + idx < Length(qubits)){
            if (ResultAsBool(M(qubits[idx+idy]))){
              set newDigit = newDigit + 2^idy;
            } 
          }
        }
        // ugh
        if (newDigit == 0){
          set newmessage = newmessage + "0";
        } elif (newDigit == 1){
          set newmessage = newmessage + "1";
        } elif (newDigit == 2){
          set newmessage = newmessage + "2";
        } elif (newDigit == 3){
          set newmessage = newmessage + "3";
        } elif (newDigit == 4){
          set newmessage = newmessage + "4";
        } elif (newDigit == 5){
          set newmessage = newmessage + "5";
        } elif (newDigit == 6){
          set newmessage = newmessage + "6";
        } elif (newDigit == 7){
          set newmessage = newmessage + "7";
        } elif (newDigit == 8){
          set newmessage = newmessage + "8";
        } elif (newDigit == 9){
          set newmessage = newmessage + "9";
        } elif (newDigit == 10){
          set newmessage = newmessage + "a";
        } elif (newDigit == 11){
          set newmessage = newmessage + "b";
        } elif (newDigit == 12){
          set newmessage = newmessage + "c";
        } elif(newDigit == 13){
          set newmessage = newmessage + "d";
        } elif (newDigit == 14){
          set newmessage = newmessage + "e";
        } elif (newDigit == 15){
          set newmessage = newmessage + "f";
        }
      }
      Message(newmessage);
    }
    adjoint(...){
      DumpQubitsAsHex(qubits, message);
    }
    controlled(controls,...){
      DumpQubitsAsHex(qubits, message);
    }
    controlled adjoint(controls,...){
      DumpQubitsAsHex(qubits, message);
    }
  }
}