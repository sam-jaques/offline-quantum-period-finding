
namespace Quantum.Chaskey
{
  open Microsoft.Quantum.Crypto.Tests.Isogenies;
  open Microsoft.Quantum.Crypto.Fp2Arithmetic;
  open Microsoft.Quantum.Crypto.Isogenies;
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
  open Quantum.BlockCipherBasics;
  open Microsoft.Quantum.Arrays;

  open Microsoft.Quantum.ModularArithmetic.DebugHelpers;


  // # Summary
  // Applies a single round of the Chaskey permutation, in-place,
  // to a 128-bit state
  operation ChaskeyPermutationRound (vs : Qubit[]) : Unit
  {
      body (...) {
      	let v0s = LittleEndian(vs[0..31]);
      	let v1s = LittleEndian(vs[32..63]);
      	let v2s = LittleEndian(vs[64..95]);
      	let v3s = LittleEndian(vs[96..127]);
      	AddIntegerNoCarry(v1s, v0s);
      	AddIntegerNoCarry(v3s, v2s);
      	(CyclicRotateRegisterMultiple)(v1s, 5);
       	(CyclicRotateRegisterMultiple)(v3s, 8);
      	BitWiseXor(v0s!, v1s!);
      	BitWiseXor(v2s!, v3s!);
      	(CyclicRotateRegisterMultiple)(v0s, 16);

      	AddIntegerNoCarry(v1s, v2s);
      	AddIntegerNoCarry(v3s, v0s);
      	(CyclicRotateRegisterMultiple)(v1s, 7);
      	(CyclicRotateRegisterMultiple)(v3s, 13);
      	BitWiseXor(v2s!, v1s!);
      	BitWiseXor(v0s!, v3s!);
      	(CyclicRotateRegisterMultiple)(v2s, 16);
      }
      controlled adjoint auto;
  }

  // # Summary
  // Applies all rounds of the Chaskey permutation
  // to a state
  operation ChaskeyPermutation(rounds : Int, vs : Qubit[]) : Unit {
  		body (...) {
  			for (idx in 0..rounds-1){
  				ChaskeyPermutationRound(vs);
  			}
  		}
  		controlled adjoint auto;
  }

  // # Summary
  // Transform the shared input to compute only once a fourth of the first round
  operation SimonFunctionFSharedPart(keyGuesses : Qubit[]) : Unit {
      body (...) {
          Fact(Length(keyGuesses) >= 64, "Needs at least 64 bits of shared input");
          let d = Length(keyGuesses) - 64;
          let v2s = LittleEndian(keyGuesses[d..d+31]);
          let v3s = LittleEndian(keyGuesses[d+32..d+63]);
      	  AddIntegerNoCarry(v3s, v2s);
       	  (CyclicRotateRegisterMultiple)(v3s, 8);
      	  BitWiseXor(v2s!, v3s!);
      }
      controlled adjoint auto;
  }

  // # Summary
  // Compute 3 fourth of the first round
  operation SimonChaskeyRemainingPartFirstRound(vs : Qubit[]) : Unit {
      body (...) {
      	let v0s = LittleEndian(vs[0..31]);
       	let v1s = LittleEndian(vs[32..63]);
     	  let v2s = LittleEndian(vs[64..95]);
       	let v3s = LittleEndian(vs[96..127]);
       	AddIntegerNoCarry(v1s, v0s);
       	(CyclicRotateRegisterMultiple)(v1s, 5);
     	  BitWiseXor(v0s!, v1s!);
     	  (CyclicRotateRegisterMultiple)(v0s, 16);
       	AddIntegerNoCarry(v1s, v2s);
       	AddIntegerNoCarry(v3s, v0s);
       	(CyclicRotateRegisterMultiple)(v1s, 7);
     	  (CyclicRotateRegisterMultiple)(v3s, 13);
     	  BitWiseXor(v2s!, v1s!);
       	BitWiseXor(v0s!, v3s!);
       	(CyclicRotateRegisterMultiple)(v2s, 16);
      }
      controlled adjoint auto;
  }

  // # Summary
  // Computes only (v1[12..22] xor (v2[28..31,0..6] <<< 16)) >>> 7
  // In the last 2 rounds of Chaskey
  // Output is in vs[5..15]
  operation SimonChaskeyLast2Rounds(vs : Qubit[]) : Unit {
  		body (...) {
        let v0s = LittleEndian(vs[0..31]);
      	let v1s = LittleEndian(vs[32..63]);
        let v2s = LittleEndian(vs[64..95]);
      	let v2sh = LittleEndian(vs[64..79]); // 16 bits
      	let v3s = LittleEndian(vs[96..127]);
        let v3sh = LittleEndian(vs[96..111]); // 16 bits
      	AddIntegerNoCarry(v1s, v0s);
      	AddIntegerNoCarry(v3sh, v2sh); // 16 bits add
        (CyclicRotateRegisterMultiple)(v1s, 5);
       	(CyclicRotateRegisterMultiple)(v3s, 8);
      	BitWiseXor(v0s!, v1s!);
      	BitWiseXor(v2sh!, v3sh!);
       	(CyclicRotateRegisterMultiple)(v0s, 16);
        let v0sh = LittleEndian(vs[0..15]); // 16 bits
      	let v1sh = LittleEndian(vs[32..47]); // 16 bits
        AddIntegerNoCarry(v1sh, v2sh); // 16 bits add
        AddIntegerNoCarry(v3sh, v0sh); // 16 bits add
       	(CyclicRotateRegisterMultiple)(v1s, 7);
      	BitWiseXor(v2sh!, v1sh!);
        // Last round
       	AddIntegerNoCarry(v1sh, v0sh); // 16 bits add
        (CyclicRotateRegisterMultiple)(v1s, 5);
  		}
  		controlled adjoint auto;
  }


  // # Summary
  // Computes the Chaskey permutation, but without shared operations
  // in the first round and with the output  as
  // (v[12+32..22+32] xor (v2[28+64..31+64,64..6+64] <<< 16)) >>> 7
  operation SimonChaskeyUnsharedPart(rounds : Int, vs : Qubit[]) : Unit {
		body (...) {
      SimonChaskeyRemainingPartFirstRound(vs);
			for (idx in 1..rounds-3){
				ChaskeyPermutationRound(vs);
			}
      SimonChaskeyLast2Rounds(vs);
		}
		controlled adjoint auto;
  }

  // # Summary
  // TimesTwo operation from Chaskey specification.
  // Requires an auxiliary qubit which is left entangled with 
  // the input.
  operation TimesTwo(xs : Qubit[], spareQubit : Qubit) : Unit {
    body (...) {
      (CyclicRotateRegister)(LittleEndian(xs + [spareQubit]));
      CNOT(spareQubit, xs[0]);
      CNOT(spareQubit, xs[1]);
      CNOT(spareQubit, xs[2]);
      CNOT(spareQubit, xs[7]);
    }
    controlled adjoint auto;
  }

  // # Summary
  // Applies the Chaskey cipher to a 128-bit message,
  // including the alterations to the key
  operation Chaskey(rounds : Int, messageLength : Int, message : Qubit[], key : Qubit[]) : Unit{
      body (...) {
        Fact(Length(key) == 128, "Key needs exactly 128 bits");
        
        BitWiseXor(key, message[0..127]);
        using (spareQubits = Qubit[2]){
          TimesTwo(key, spareQubits[0]);
          if (messageLength < 128){
            TimesTwo(key, spareQubits[1]);
            X(message[messageLength]);
          }
          BitWiseXor(key, message[0..127]);
          ChaskeyPermutation(rounds, message[0..127]);
          BitWiseXor(key,message[0.. 127]);
          (Adjoint TimesTwo)(key, spareQubits[0]);
          if (messageLength < 128){
            (Adjoint TimesTwo)(key, spareQubits[1]);
          }
        }
      }
      controlled adjoint auto;
  }

  // # Summary
  // The Chaskey cipher, formatted for use in a Grover oracle
  // Speficially, it assumes the key is processed
  operation ChaskeyGroverCipher(rounds : Int, key : Qubit[], message : Qubit[]) : Unit {
    body (...){
      BitWiseXor(key, message);
      ChaskeyPermutation(rounds, message);
      BitWiseXor(key,message);
    } adjoint auto;
  }

  // # Summary
  // A Grover iteration for an exhaustive key search against Chaskey.
  // 
  // # Inputs
  // ## rounds
  // The number of rounds for the Chaskey permutation
  // ## key
  // Qubits for the key; needs exactly 128
  // ## messages
  // Qubits representing both the nonce and message for a number of plaintext/ciphertext pairs
  // Must be a multiple of 128
  // ## phase
  // Qubit in the |-> for the phase
   operation ChaskeyGrover(rounds : Int, key : Qubit[], messages : Qubit[], phase : Qubit) : Unit{
      body (...) {
        Fact(Length(key) == 128, "Key needs exactly 128 bits");
        let messageBlocks = Microsoft.Quantum.Arrays.Chunks(128, messages);
        for (idx in 0..Length(messageBlocks) - 1){
          BitWiseXor(key, messageBlocks[idx]);
        }
        using (spareQubit = Qubit()){
          GroverOracle(128, key, messages, phase, ChaskeyGroverCipher(rounds, _, _), TimesTwo(_, spareQubit));
        }
        for (idx in 0..Length(messageBlocks) - 1){
          BitWiseXor(key, messageBlocks[idx]);
        }
      }
       adjoint auto;
  }
  

   // # Summary
  // Computes the permutation and copies out the result to act as the function f in the offline Simon attack.
  // This incorporates optimizations to the first and last rounds of the cipher.
  // Requires Length(keyGuesses) >= 64
  // 
  // # Inputs
  // ## rounds
  // Number of rounds for the permutation
  // ## outputLength
  // The number of bits to copy out (at most 11)
  // ## xs
  // Qubits representing "x", the portion of the state on which Simon's algorithm is run
  // ## keyGuesses
  // Qubits representing "i", the portion of the state that is being exhaustively searched
  // ## outputs
  // Qubits to copy the output onto 
  operation SimonFunctionFUnsharedPart (rounds : Int, outputLength : Int, xs : Qubit[], keyGuesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...){
      Fact(outputLength <= 11, "Output length can be at most 11 bits");
      Fact(Length(keyGuesses) >= 64, "Needs at least 64 bits of shared input");
      SimonChaskeyUnsharedPart(rounds, xs + keyGuesses);
      for (idx in 0..outputLength-1){
        CNOT((xs+keyGuesses)[idx+5], outputs[idx]);
        CNOT((xs+keyGuesses)[idx+5+32], outputs[idx]);
      }
      (Adjoint SimonChaskeyUnsharedPart)(rounds, xs + keyGuesses);
    }
  }

  // # Summary
  // The same as SimonFunctionFUnshared part, but without optimizations
  // Infers the outputlength from the length of the qubit array.
  operation SimonFunctionF (rounds : Int, xs : Qubit[], keyGuesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...){
      ChaskeyPermutation(rounds, xs + keyGuesses);
      for (idx in 0.. Length(outputs) - 1){
        CNOT((xs+keyGuesses)[idx], outputs[idx]);
      }
      (Adjoint ChaskeyPermutation)(rounds, xs + keyGuesses);
    }
  }

  // # Summary
  // Checks a test vector from the Chaskey specification.
  // https://mouha.be/wp-content/uploads/chaskey12.c
  @Test("ToffoliSimulator")
  operation ChaskeyTest () : Unit {
    using (messages = Qubit[128]){
      using (keys = Qubit[128]){
        let key = [0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88, 0x77, 0x66, 0x55,0x44, 0x33, 0x22, 0x11, 0x00];
        // Construct the key as a BigInt in such a way that the endianness is correct
        mutable intKey = 0L;
        for (idx in 0..(1)..15){
          set intKey = intKey*(2L^8);
          set intKey = intKey + IntAsBigInt(key[idx]);
        }
        let tagArray = [
          [ 0xdd, 0x3e, 0x18, 0x49, 0xd6, 0x82, 0x45, 0x55 ], //tag of 0x0000..
          [ 0xed, 0x1d, 0xa8, 0x9e, 0xc9, 0x31, 0x79, 0xca ], //0x0001..
          [ 0x98, 0xfe, 0x20, 0xa3, 0x43, 0xcd, 0x66, 0x6f ], //0x000102..
          [ 0xf6, 0xf4, 0x18, 0xac, 0xdd, 0x7d, 0x9f, 0xa1 ], //0x00010203
          [ 0x4c, 0xf0, 0x49, 0x60, 0x09, 0x99, 0x49, 0xf3 ],
          [ 0x75, 0xc8, 0x32, 0x52, 0x65, 0x3d, 0x3b, 0x57 ],
          [ 0x96, 0x4b, 0x04, 0x61, 0xfb, 0xe9, 0x22, 0x73 ],
          [ 0x14, 0x1f, 0xa0, 0x8b, 0xbf, 0x39, 0x96, 0x36 ],
          [ 0x41, 0x2d, 0x98, 0xed, 0x93, 0x6d, 0x4a, 0xb2 ],
          [ 0xfb, 0x0d, 0x98, 0xbc, 0x70, 0xe3, 0x05, 0xf9 ],
          [ 0x36, 0xf8, 0x8e, 0x1f, 0xda, 0x86, 0xc8, 0xab ],
          [ 0x4d, 0x1a, 0x18, 0x15, 0x86, 0x8a, 0x5a, 0xa8 ],
          [ 0x7a, 0x79, 0x12, 0xc1, 0x99, 0x9e, 0xae, 0x81 ],
          [ 0x9c, 0xa1, 0x11, 0x37, 0xb4, 0xa3, 0x46, 0x01 ],
          [ 0x79, 0x05, 0x14, 0x2f, 0x3b, 0xe7, 0x7e, 0x67 ],
          [ 0x6a, 0x3e, 0xe3, 0xd3, 0x5c, 0x04, 0x33, 0x97 ],
          [ 0xd1, 0x39, 0x70, 0xd7, 0xbe, 0x9b, 0x23, 0x50 ]
        ];
        mutable tag = 0L;
        mutable intMessage = 0L;
        for (idy in 15..(-1)..0){
          // Construct the message
          set intMessage = 0L;
          for (idx in idy..(-1)..0){
            set intMessage = intMessage <<< 8;
            set intMessage = intMessage + IntAsBigInt(idx);
          }
          
          ApplyXorInPlaceL(intMessage, LittleEndian(messages));
          ApplyXorInPlaceL(intKey, LittleEndian(keys));
        

          Chaskey(12, (idy+1)*8, messages, keys);

         
          let outputKey = MeasureBigInteger(LittleEndian(keys));
          Fact(outputKey == intKey, "Chaskey key not returned to the same value");
          // Construct the tag
          set tag = 0L;
          for (idx in 7..(-1)..0){
            set tag = tag*(2L^8);
            set tag = tag + IntAsBigInt(tagArray[idy+1][idx]);
          }
          let measuredTag = MeasureBigInteger(LittleEndian(messages[0..63]));
          Fact(measuredTag == tag, "Chaskey tag failed");
          let restOfMessage = MeasureBigInteger(LittleEndian(messages[64..127]));
        }
      }
    }
  }


// # Summary
// Inverts the part of the computation not done by SimonFunctionFUnsharedPart
operation LinearCombinationChaskeyTest(vs : Qubit[]) : Unit {
    body (...){
      	let v1s = LittleEndian(vs[32..63]);
        let v2s = LittleEndian(vs[64..95]);
        (CyclicRotateRegisterMultiple)(v2s, 16);
        BitWiseXor(v2s!,v1s!);
        (CyclicRotateRegisterMultiple)(v1s, 25);
    }
}

  // # Summary
  // Checks that the optimized variant computes the same thing as
  // the reference implementation for random messages
  @Test("ToffoliSimulator")
  operation OptimizedChaskeyTest() : Unit {
    for (idx in 0..4) {
      using ((message1, message2, outputs) = (Qubit[128], Qubit[128], Qubit[11])) {
        // Pick random message
        let testInt = RandomBigInt(2L^128);
        // Write into quantum registers
        ApplyXorInPlaceL(testInt, LittleEndian(message1));
        ApplyXorInPlaceL(testInt,  LittleEndian(message2));
        // Compute with the full circuit
        ChaskeyPermutation(12, message1);
       // Compute with the truncated circuit and copy bits 5..15 to output qubits
        SimonFunctionFSharedPart(message2[50..127]);
        // Transform the full Chaskey with the linear combination
        LinearCombinationChaskeyTest(message1);
        // Measures bits 5..15 from the full circuit
        let resultInt = MeasureBigInteger(LittleEndian(message1[32+5..32+15]));
        //Measures the output from the truncated circuit
        let truncatedInt = MeasureBigInteger(LittleEndian(outputs));

        Fact(resultInt == truncatedInt, $"Optimized Chaskey failed on input {testInt}: found {truncatedInt}, should have {resultInt}");
        ResetAll(message1 + message2 + outputs);
      }
    }
  }

   
}