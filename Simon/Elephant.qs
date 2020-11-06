
namespace Quantum.Elephant
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
  open Quantum.Keccak;
  open Microsoft.Quantum.ModularArithmetic.DebugHelpers;


  // # Summary
  // Affine operation for decomposition of the SpongeNT S-box
  // Should match output of accompanying sage script
  operation A3 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[2], states[0]);
        CNOT(states[1], states[2]);
        CNOT(states[3], states[1]);

        SWAP(states[2], states[3]);

        X(states[0]);

      } adjoint auto;
  } 

  // # Summary
  // Affine operation for decomposition of the SpongeNT S-box
  // Should match output of accompanying sage script
  operation A2 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[1], states[3]);

        SWAP(states[0], states[3]);


      } adjoint auto;
  }
  
  // # Summary
  // Affine operation for decomposition of the SpongeNT S-box
  // Should match output of accompanying sage script
  operation A1 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[0], states[2]);
        CNOT(states[3], states[0]);
        CNOT(states[2], states[1]);
        CNOT(states[1], states[3]);

        SWAP(states[2], states[3]);
        SWAP(states[2], states[1]);

        X(states[0]);
        X(states[2]);
        X(states[3]);
      } adjoint auto;
  }

  // # Summary
  // Performs the SpongeNT S-box, in-place, on 4 qubits
  //
  // # References
  // https://homes.esat.kuleuven.be/~snikova/ti_tools.html
  operation FastSBox(nibble : Qubit[]) : Unit {
    body (...) { 
      A3(nibble);
      Q294(nibble);
      A2(nibble);
      Q12(nibble);
      A1(nibble);
    } adjoint auto;
  }

  // # Summary
  // Performs the SpongeNT s-box, parallel and in-place,
  // on an array of qubits. Number of qubits must be a multiple of 4.
  operation FastSBoxMulti(states : Qubit[]) : Unit {
    body (...){
      Fact(Length(states) % 4 == 0, "Needs 4 bits to apply sbox");
      for (idx in 0..4..Length(states) - 1){
        FastSBox(states[idx..idx+3]);
      }
    } adjoint auto;
  }
  
  // # Summary
  // Permutes the qubits in `states` according to the p-layer
  // of the Spongent permutation.
  operation PLayer160 (states : Qubit[]) : Unit {
     body (...){
      SWAP(states[145], states[76]);
      SWAP(states[103], states[145]);
      SWAP(states[94], states[103]);
      SWAP(states[58], states[94]);
      SWAP(states[73], states[58]);
      SWAP(states[133], states[73]);
      SWAP(states[55], states[133]);
      SWAP(states[61], states[55]);
      SWAP(states[85], states[61]);
      SWAP(states[22], states[85]);
      SWAP(states[88], states[22]);
      SWAP(states[34], states[88]);
      SWAP(states[136], states[34]);
      SWAP(states[67], states[136]);
      SWAP(states[109], states[67]);
      SWAP(states[118], states[109]);
      SWAP(states[154], states[118]);
      SWAP(states[139], states[154]);
      SWAP(states[79], states[139]);
      SWAP(states[157], states[79]);
      SWAP(states[151], states[157]);
      SWAP(states[127], states[151]);
      SWAP(states[31], states[127]);
      SWAP(states[124], states[31]);
      SWAP(states[19], states[124]);
      SWAP(states[17], states[44]);
      SWAP(states[68], states[17]);
      SWAP(states[113], states[68]);
      SWAP(states[134], states[113]);
      SWAP(states[59], states[134]);
      SWAP(states[77], states[59]);
      SWAP(states[149], states[77]);
      SWAP(states[119], states[149]);
      SWAP(states[158], states[119]);
      SWAP(states[155], states[158]);
      SWAP(states[143], states[155]);
      SWAP(states[95], states[143]);
      SWAP(states[62], states[95]);
      SWAP(states[89], states[62]);
      SWAP(states[38], states[89]);
      SWAP(states[152], states[38]);
      SWAP(states[131], states[152]);
      SWAP(states[47], states[131]);
      SWAP(states[29], states[47]);
      SWAP(states[116], states[29]);
      SWAP(states[146], states[116]);
      SWAP(states[107], states[146]);
      SWAP(states[110], states[107]);
      SWAP(states[122], states[110]);
      SWAP(states[11], states[122]);
      SWAP(states[96], states[24]);
      SWAP(states[66], states[96]);
      SWAP(states[105], states[66]);
      SWAP(states[102], states[105]);
      SWAP(states[90], states[102]);
      SWAP(states[42], states[90]);
      SWAP(states[9], states[42]);
      SWAP(states[36], states[9]);
      SWAP(states[144], states[36]);
      SWAP(states[99], states[144]);
      SWAP(states[78], states[99]);
      SWAP(states[153], states[78]);
      SWAP(states[135], states[153]);
      SWAP(states[63], states[135]);
      SWAP(states[93], states[63]);
      SWAP(states[54], states[93]);
      SWAP(states[57], states[54]);
      SWAP(states[69], states[57]);
      SWAP(states[117], states[69]);
      SWAP(states[150], states[117]);
      SWAP(states[123], states[150]);
      SWAP(states[15], states[123]);
      SWAP(states[60], states[15]);
      SWAP(states[81], states[60]);
      SWAP(states[6], states[81]);
      SWAP(states[48], states[12]);
      SWAP(states[33], states[48]);
      SWAP(states[132], states[33]);
      SWAP(states[51], states[132]);
      SWAP(states[45], states[51]);
      SWAP(states[21], states[45]);
      SWAP(states[84], states[21]);
      SWAP(states[18], states[84]);
      SWAP(states[72], states[18]);
      SWAP(states[129], states[72]);
      SWAP(states[39], states[129]);
      SWAP(states[156], states[39]);
      SWAP(states[147], states[156]);
      SWAP(states[111], states[147]);
      SWAP(states[126], states[111]);
      SWAP(states[27], states[126]);
      SWAP(states[108], states[27]);
      SWAP(states[114], states[108]);
      SWAP(states[138], states[114]);
      SWAP(states[75], states[138]);
      SWAP(states[141], states[75]);
      SWAP(states[87], states[141]);
      SWAP(states[30], states[87]);
      SWAP(states[120], states[30]);
      SWAP(states[3], states[120]);
      SWAP(states[32], states[8]);
      SWAP(states[128], states[32]);
      SWAP(states[35], states[128]);
      SWAP(states[140], states[35]);
      SWAP(states[83], states[140]);
      SWAP(states[14], states[83]);
      SWAP(states[56], states[14]);
      SWAP(states[65], states[56]);
      SWAP(states[101], states[65]);
      SWAP(states[86], states[101]);
      SWAP(states[26], states[86]);
      SWAP(states[104], states[26]);
      SWAP(states[98], states[104]);
      SWAP(states[74], states[98]);
      SWAP(states[137], states[74]);
      SWAP(states[71], states[137]);
      SWAP(states[125], states[71]);
      SWAP(states[23], states[125]);
      SWAP(states[92], states[23]);
      SWAP(states[50], states[92]);
      SWAP(states[41], states[50]);
      SWAP(states[5], states[41]);
      SWAP(states[20], states[5]);
      SWAP(states[80], states[20]);
      SWAP(states[2], states[80]);
      SWAP(states[16], states[4]);
      SWAP(states[64], states[16]);
      SWAP(states[97], states[64]);
      SWAP(states[70], states[97]);
      SWAP(states[121], states[70]);
      SWAP(states[7], states[121]);
      SWAP(states[28], states[7]);
      SWAP(states[112], states[28]);
      SWAP(states[130], states[112]);
      SWAP(states[43], states[130]);
      SWAP(states[13], states[43]);
      SWAP(states[52], states[13]);
      SWAP(states[49], states[52]);
      SWAP(states[37], states[49]);
      SWAP(states[148], states[37]);
      SWAP(states[115], states[148]);
      SWAP(states[142], states[115]);
      SWAP(states[91], states[142]);
      SWAP(states[46], states[91]);
      SWAP(states[25], states[46]);
      SWAP(states[100], states[25]);
      SWAP(states[82], states[100]);
      SWAP(states[10], states[82]);
      SWAP(states[40], states[10]);
      SWAP(states[1], states[40]);
     }
    controlled adjoint auto;
  }

  // # Summary
  // Permutes the qubits in `states` according to the p-layer
  // of the Spongent permutation.
  operation PLayer176 (states : Qubit[]) : Unit {
     body (...) { 
      SWAP(states[150], states[125]);
      SWAP(states[75], states[150]);
      SWAP(states[70], states[105]);
      SWAP(states[35], states[140]);
      SWAP(states[130], states[120]);
      SWAP(states[170], states[130]);
      SWAP(states[155], states[170]);
      SWAP(states[95], states[155]);
      SWAP(states[30], states[95]);
      SWAP(states[50], states[100]);
      SWAP(states[25], states[50]);
      SWAP(states[65], states[60]);
      SWAP(states[85], states[65]);
      SWAP(states[165], states[85]);
      SWAP(states[135], states[165]);
      SWAP(states[15], states[135]);
      SWAP(states[49], states[56]);
      SWAP(states[21], states[49]);
      SWAP(states[84], states[21]);
      SWAP(states[161], states[84]);
      SWAP(states[119], states[161]);
      SWAP(states[126], states[119]);
      SWAP(states[154], states[126]);
      SWAP(states[91], states[154]);
      SWAP(states[14], states[91]);
      SWAP(states[160], states[40]);
      SWAP(states[115], states[160]);
      SWAP(states[110], states[115]);
      SWAP(states[90], states[110]);
      SWAP(states[10], states[90]);
      SWAP(states[112], states[28]);
      SWAP(states[98], states[112]);
      SWAP(states[42], states[98]);
      SWAP(states[168], states[42]);
      SWAP(states[147], states[168]);
      SWAP(states[63], states[147]);
      SWAP(states[77], states[63]);
      SWAP(states[133], states[77]);
      SWAP(states[7], states[133]);
      SWAP(states[96], states[24]);
      SWAP(states[34], states[96]);
      SWAP(states[136], states[34]);
      SWAP(states[19], states[136]);
      SWAP(states[76], states[19]);
      SWAP(states[129], states[76]);
      SWAP(states[166], states[129]);
      SWAP(states[139], states[166]);
      SWAP(states[31], states[139]);
      SWAP(states[124], states[31]);
      SWAP(states[146], states[124]);
      SWAP(states[59], states[146]);
      SWAP(states[61], states[59]);
      SWAP(states[69], states[61]);
      SWAP(states[101], states[69]);
      SWAP(states[54], states[101]);
      SWAP(states[41], states[54]);
      SWAP(states[164], states[41]);
      SWAP(states[131], states[164]);
      SWAP(states[174], states[131]);
      SWAP(states[171], states[174]);
      SWAP(states[159], states[171]);
      SWAP(states[111], states[159]);
      SWAP(states[94], states[111]);
      SWAP(states[26], states[94]);
      SWAP(states[104], states[26]);
      SWAP(states[66], states[104]);
      SWAP(states[89], states[66]);
      SWAP(states[6], states[89]);
      SWAP(states[80], states[20]);
      SWAP(states[145], states[80]);
      SWAP(states[55], states[145]);
      SWAP(states[45], states[55]);
      SWAP(states[5], states[45]);
      SWAP(states[48], states[12]);
      SWAP(states[17], states[48]);
      SWAP(states[68], states[17]);
      SWAP(states[97], states[68]);
      SWAP(states[38], states[97]);
      SWAP(states[152], states[38]);
      SWAP(states[83], states[152]);
      SWAP(states[157], states[83]);
      SWAP(states[103], states[157]);
      SWAP(states[62], states[103]);
      SWAP(states[73], states[62]);
      SWAP(states[117], states[73]);
      SWAP(states[118], states[117]);
      SWAP(states[122], states[118]);
      SWAP(states[138], states[122]);
      SWAP(states[27], states[138]);
      SWAP(states[108], states[27]);
      SWAP(states[82], states[108]);
      SWAP(states[153], states[82]);
      SWAP(states[87], states[153]);
      SWAP(states[173], states[87]);
      SWAP(states[167], states[173]);
      SWAP(states[143], states[167]);
      SWAP(states[47], states[143]);
      SWAP(states[13], states[47]);
      SWAP(states[52], states[13]);
      SWAP(states[33], states[52]);
      SWAP(states[132], states[33]);
      SWAP(states[3], states[132]);
      SWAP(states[32], states[8]);
      SWAP(states[128], states[32]);
      SWAP(states[162], states[128]);
      SWAP(states[123], states[162]);
      SWAP(states[142], states[123]);
      SWAP(states[43], states[142]);
      SWAP(states[172], states[43]);
      SWAP(states[163], states[172]);
      SWAP(states[127], states[163]);
      SWAP(states[158], states[127]);
      SWAP(states[107], states[158]);
      SWAP(states[78], states[107]);
      SWAP(states[137], states[78]);
      SWAP(states[23], states[137]);
      SWAP(states[92], states[23]);
      SWAP(states[18], states[92]);
      SWAP(states[72], states[18]);
      SWAP(states[113], states[72]);
      SWAP(states[102], states[113]);
      SWAP(states[58], states[102]);
      SWAP(states[57], states[58]);
      SWAP(states[53], states[57]);
      SWAP(states[37], states[53]);
      SWAP(states[148], states[37]);
      SWAP(states[67], states[148]);
      SWAP(states[93], states[67]);
      SWAP(states[22], states[93]);
      SWAP(states[88], states[22]);
      SWAP(states[2], states[88]);
      SWAP(states[16], states[4]);
      SWAP(states[64], states[16]);
      SWAP(states[81], states[64]);
      SWAP(states[149], states[81]);
      SWAP(states[71], states[149]);
      SWAP(states[109], states[71]);
      SWAP(states[86], states[109]);
      SWAP(states[169], states[86]);
      SWAP(states[151], states[169]);
      SWAP(states[79], states[151]);
      SWAP(states[141], states[79]);
      SWAP(states[39], states[141]);
      SWAP(states[156], states[39]);
      SWAP(states[99], states[156]);
      SWAP(states[46], states[99]);
      SWAP(states[9], states[46]);
      SWAP(states[36], states[9]);
      SWAP(states[144], states[36]);
      SWAP(states[51], states[144]);
      SWAP(states[29], states[51]);
      SWAP(states[116], states[29]);
      SWAP(states[114], states[116]);
      SWAP(states[106], states[114]);
      SWAP(states[74], states[106]);
      SWAP(states[121], states[74]);
      SWAP(states[134], states[121]);
      SWAP(states[11], states[134]);
      SWAP(states[44], states[11]);
      SWAP(states[1], states[44]);
     }
    controlled adjoint auto;
  }

  // # Summary
  // Returns an array of all the IVs produced by the LFSR
  // in the Spongent permutation, with a given start value
  // If the result is T, then T[i] will be the result of applying
  // the LFSR i times to `start`.
  //
  // Matches the code at https://github.com/TimBeyne/Elephant,
  // rather than the Elephant specification
  //
  // # Inputs
  // ## start
  // 7-bit start value, given in the Elephant specification
  // ## size
  // The number of iterations to include in the table.
  //
  // # Outputs
  // ## Int[]
  // An array of the resulting LFSR values
  function ICounter (start : Int, size : Int) : Int[] {
    mutable counter = new Int[size];
    set counter w/= 0 <- start; 
    for (idx in 1 .. size - 1){
      // >>> makes numbers less significant
      // <<< makes them more significant
      let counter1 = (((0x40 &&& counter[idx - 1]) >>> 6) ^^^ ((0x20 &&& counter[idx - 1]) >>> 5));
      let counter2 = (counter[idx - 1] <<< 1);
      set counter w/= idx <- counter1 ||| counter2;
      set counter w/= idx <- (counter[idx] &&& 0x7f);
    }
    return counter;
  }


  // # Summary
  // Computes the permutation of a specified block size 
  // (Spongent for 160 and 176, Keccak for 200)
  // on a block of qubits, in-place. 
  // Since the S box is out-of-place, but easy to invert, this takes a simple pebbling strategy
  // of computing the next step and using that to erase the previous step
  // 
  // # Inputs
  // ## blockSize
  // Elephant cipher block size (currently 160 and 176 supported)
  // ## states
  // Qubit array of inputs
  operation ElephantPermutation (blockSize : Int, states : Qubit[]) : Unit {
    body (...){
      // These follow the code at https://github.com/TimBeyne/Elephant,
      // not the specification
      if (blockSize <= 176){
        let counterStart = (blockSize == 160) ? 0x75 | 0x45;
        let nRounds = (blockSize == 160) ? 80 | 90;
        let PLayer = (blockSize == 160) ? PLayer160 | PLayer176;
        let counter = ICounter(counterStart, nRounds);
        for (idx in 1..nRounds){
          ApplyXorInPlace(counter[idx-1], LittleEndian(states[0..6]));
          ApplyXorInPlace(counter[idx-1], LittleEndian(states[blockSize - 1..-1..blockSize - 7]));
          FastSBoxMulti(states);
          PLayer(states);
        }
      } else {
        Keccak(12 + 2 * 3, states);
      }
    }
    adjoint auto;
  }

  // # Summary
  // Computes the first 12 bits of the permutation, minus the last linear layer
  // For SpongeNT, also removed the Sbox that only depend on the guesses in the first round
  // For Keccak, the first 15 bits are computed
  // 
  // # Inputs
  // ## blockSize
  // Blocksize for which elephant variant (160, 176, 200) to use
  // ## states
  // The qubit array to permute
  // ## guessLength
  // The number of qubits that have already been "guessed" as part of the Grover search;
  // hence, no operations will be applied to the last `guessLength` qubits
  operation SimonElephant(blockSize : Int, states : Qubit[], guesslength : Int) : Unit {
        body (...){

      if (blockSize <= 176){
        let counterStart = (blockSize == 160) ? 0x75 | 0x45;
        let nRounds = (blockSize == 160) ? 80 | 90;
        let PLayer = (blockSize == 160) ? PLayer160 | PLayer176;
        let counter = ICounter(counterStart, nRounds);

        // First round
        ApplyXorInPlace(counter[0], LittleEndian(states[0..6]));
        let sboxSliceLength = blockSize - 4*((guesslength)/4);
        FastSBoxMulti(states[0..sboxSliceLength - 1]);
        PLayer(states);

        for (idx in 2..nRounds-1){
           ApplyXorInPlace(counter[idx-1], LittleEndian(states[0..6]));
           ApplyXorInPlace(counter[idx-1], LittleEndian(states[blockSize - 1..-1..blockSize - 7]));
           FastSBoxMulti(states);
           PLayer(states);
         }

         // Last round
         ApplyXorInPlace(counter[nRounds-1], LittleEndian(states[0..6]));
         FastSBoxMulti(states[0..11]);
      } else {
        SimonKeccak(12 + 2 * 3, states);
      }
    }
    adjoint auto;
  }


  // # Summary
  // Encrypts a message with a specified nonce and key, according to a single block
  // of the Elephant cipher. Uses the length of `block` to decide which Spongent to use.
  // The value in the `nonce` qubits is overwritten with the encrypted data.
  // 
  // # Inputs
  // ## key
  // 128 qubits containing the key
  // ## nonce
  // {160,176} qubits containing the nonce in the first 96 qubits. Contains the output
  // after the operation is finished.
  // ## block
  // {160,176} qubits containing the message to encrypt.
  operation ElephantEncrypt(key : Qubit[], nonce : Qubit[], block : Qubit[]) : Unit {
    body (...) {
      let k = Length(key);
      let n = Length(block);
      using (spareKeys = Qubit[n - k]){
        let maskedKey = key + spareKeys;
        ElephantPermutation(n, maskedKey);
        BitWiseXor(maskedKey, nonce);
        ElephantPermutation(n, nonce);
        BitWiseXor(block, nonce);
        BitWiseXor(maskedKey, nonce);
        (Adjoint ElephantPermutation)(n, maskedKey);
      }
    }
    adjoint auto;
  }


  // # Summary
  // Processes and encrypts with Elephant in a way suitable for Grover's algorithm
  operation ElephantGroverCipher(blockSize : Int, key : Qubit[], message : Qubit[]) : Unit {
    body (...){
      let nonce = message[0..blockSize - 1];
      let block = message[blockSize .. 2*blockSize - 1];
      BitWiseXor(key, nonce);
      ElephantPermutation(blockSize, nonce);
      BitWiseXor(block, nonce);
      BitWiseXor(key, nonce);
    } adjoint auto;
  }

  // # Summary
  // Performs a single Grover iteration for an attack against elephant.
  // 
  // # Inputs
  // ## blockSize
  // A block size in 160, 176, 200
  // ## key
  // Qubits for the key; needs exactly 128
  // ## messages
  // Qubits representing both the nonce and message for a number of plaintext/ciphertext pairs
  // Must be a multiple of twice the block size
  // ## phase
  // Qubit in the |-> for the phase
  operation ElephantGrover(blockSize : Int, key : Qubit[], messages : Qubit[], phase : Qubit) : Unit {
    body (...){
      Fact ((Length(messages) % 2*blockSize) == 0, $"Message length is {Length(messages)}, must be multiple of twice the block length");
      Fact(Length(key) == 128, $"Key is incorrect length for Elephant");
      using (keySpares = Qubit[blockSize - 128]){
        GroverOracle(2*blockSize, key + keySpares, messages, phase, ElephantGroverCipher(blockSize, _, _), ElephantPermutation(blockSize, _)); 
      }
    }
  }

  // # Summary
  // Computes the permutation and copies out the result to act as the function f in the offline Simon attack.
  // This incorporates optimizations to the first and last rounds of the cipher.
  //
  // # Inputs
  // ## outputLength
  // The number of bits of output needed (often 11)
  // Must be at most 15 (for Elephant-200) or 12 (Elephant-160,176)
  // ## blockSize
  // Elephant block size (160, 176, 200)
  // ## xs
  // Qubits representing "x", the portion of the state on which Simon's algorithm is run
  // ## keyGuesses
  // Qubits representing "i", the portion of the state that is being exhaustively searched
  // ## outputs
  // outputs
  // Qubits to copy the result onto
  operation SimonFunctionFUnsharedPart(outputLength : Int, blockSize : Int, xs : Qubit[], keyGuesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...) {
      Fact(outputLength <= (blockSize == 200 ? 15 | 12), "Output length too long");
      SimonElephant(blockSize, xs + keyGuesses, Length(keyGuesses));
      // The S-box in Keccak applies to non-contiguous indices of qubits, based on how
      // this implementation indexes qubits. This returns a re-indexed array so that 
      // (0,y,z), (1,y,z),... (4,y,z) have sequential indices for each y,z.
      let permutedQubits = ((blockSize==200) ? ShortState(15, KeccakState(xs+keyGuesses, 8)) | xs + keyGuesses);
      for (idx in 0.. outputLength - 1){
        CNOT(permutedQubits[idx], outputs[idx]);
      }
      (Adjoint SimonElephant)(blockSize, xs + keyGuesses,Length(keyGuesses));
    }
    adjoint auto;
  }

  // # Summary
  // Computes the permutation and copies out the result to act as the function f in the offline Simon attack.
  // Does not include any optimizations
  //
  // # Inputs
  // ## blockSize
  // Elephant block size (160, 176, 200)
  // ## xs
  // Qubits representing "x", the portion of the state on which Simon's algorithm is run
  // ## keyGuesses
  // Qubits representing "i", the portion of the state that is being exhaustively searched
  // ## outputs
  // outputs
  // Qubits to copy the result onto
  operation SimonFunctionF(blockSize : Int, xs : Qubit[], keyGuesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...) {
      ElephantPermutation(blockSize, xs + keyGuesses);
      for (idx in 0.. Length(outputs) - 1){
        CNOT((xs+keyGuesses)[idx], outputs[idx]);
      }
      (Adjoint ElephantPermutation)(blockSize, xs + keyGuesses);
    }
    adjoint auto;
  }

  // # Summary
  // Tests the Elephant cipher at a block size of 160 or 176, with
  // 5 prespecified nonces and keys (with an all-zeros message).
  // 
  // # Inputs
  // ## blockSize
  // The block size.
  operation TestElephant(blockSize : Int) : Unit {
    Fact(blockSize == 160 or blockSize == 176 or blockSize == 200, $"Block size {blockSize} invalid. Only 160, 176, 200 supported.");
    let nTests =5;
    let testKeys = [0x00L, 
      0xefdfcebdac9b8a796857463524130201L,
      0xefdfcebdac9b8a796857463524130201L,
      0x611F773BADB90AB89168425E61CD9556L,
      0x17A0D3611D6653CC0CE77FFBF974F600L];
    let testNonces = [0x00L, 
      0x00L,
      0x72F685BCF7223D395B0D23AEL,
      0x4A7807C55E767BDF0DCA51D7L,
      0x9AD7F03A851FFB97B165A48CL];
    let testCiphertexts = (blockSize == 160) ? [0x66D91AD1EFC161BE8E09F7BA893A956A741A73E5L,
      0xa553272421c7929c107950bbdfea4c451e37bd7fL, 
      0xdf8aa2fd5960f2001f9c9e4ede870272add61a42L,
      0xffbd1be78f85cf5a3c09db35826bcab69f0b6eddL,
      0x7cc9ae4c11202e9beba89c6a5d383e7201dd921bL] | ((blockSize == 176) ?
      [0x081210727d2db2cf777f47bb9073e82eeff362ed4d63L,
      0x3025d37cc6b6ac4cde1a8061fd2eb9143ce9fdd0b666L,
      0x9e7dc41f2366e144361e3af222ff7f499688841e9e43L,
      0x4f7dca23b6822aee730690895a6c69a84919570b63abL,
      0xfd11f49163b499826a99c55855d008f62ce0c6e35a71L] |
      [0x74e8eb950b4ec4ce028c7d5d92637633bb54f91b8e104ec727L,
      0xfc0ae09b232103ed88fdb346afc7a055dbee6b07f025f73ddeL,
      0x529a6b4bcb28019dc443052b9b323e1d78ec44bb4624b07890L,
      0x023e354ac9d75654aee5a4dedf3291009a2fdb1cc0626a4adcL,
      0x8dc283316c1c42f14dc75addae452de76ae61d0cb7d26d605aL
      ]);

    using ((key, nonce, message) = (Qubit[128], Qubit[blockSize], Qubit[blockSize])){
      for (idx in 0..nTests - 1){
        ApplyXorInPlaceL(testKeys[idx], LittleEndian(key));
        ApplyXorInPlaceL(testNonces[idx], LittleEndian(nonce[0..95]));
        ElephantEncrypt(key, nonce, message);
        let resultCiphertext = MeasureBigInteger(LittleEndian(nonce));
        Fact(resultCiphertext == testCiphertexts[idx], $"Failed test {idx} with key {testKeys[idx]} and nonce {testNonces[idx]}");
        ResetAll(key + nonce + message);
      }
    }
  }

  // # Summary
  // Tests all Elephant block sizes.
  @Test("ToffoliSimulator")
  operation ElephantTest() : Unit {
    Message("Testing 160");
    TestElephant(160);
    Message("Testing 176");
    TestElephant(176);
    Message("Testing 200");
    TestElephant(200);
  }
 

  // # Summary
  // Returns an array S such that S[i] will be the result of 
  // apply the S-box to an integer i (from 0 to 15).
  // SBoxInv returns the inverse SBox, i.e., SBoxInv()[SBox()[i]] = i
  function SBox () : Int[] {
    return  [14, 13, 11, 0, 2, 1, 4, 15, 7, 10, 8, 5, 9, 12, 3, 6];
  }
  function SBoxInv () : Int[] {
    return [3, 5, 4, 14, 6, 11, 15, 8, 10, 12, 9, 2, 13, 1, 0, 7];
  }


  // # Summary
  // Tests the S-box for Spongent
  // by comparing to pre-computed arrays
  @Test("ToffoliSimulator")
  operation SBoxTest() : Unit{
    using (states = Qubit[4]){
      let sbox = SBox();
      let sboxinv = SBoxInv();
      for (idx in 0..15){
        ApplyXorInPlace(idx, LittleEndian(states));
        FastSBox(states);
        let result = MeasureBigInteger(LittleEndian(states));
        Fact(result == IntAsBigInt(sbox[idx]), $"Failed on {idx}, returned {result}");
      }
      for (idx in 0..15){
        ApplyXorInPlace(idx, LittleEndian(states));
        (Adjoint FastSBox)(states);
        let result = MeasureBigInteger(LittleEndian(states));
        Fact(result == IntAsBigInt(sboxinv[idx]), $"Failed on {idx}, returned {result}");
      }
    }
  }

}