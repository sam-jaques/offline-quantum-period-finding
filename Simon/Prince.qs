
namespace Quantum.Prince
{
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Crypto.Basics;
  open Microsoft.Quantum.Crypto.Arithmetic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Canon;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Math;
  open Microsoft.Quantum.Random;
  open Microsoft.Quantum.Diagnostics;
  open Quantum.BlockCipherBasics;

  open Microsoft.Quantum.ModularArithmetic.DebugHelpers;

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script
  operation A1 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[1], states[0]);
         X(states[2]);
         X(states[3]);
        CNOT(states[1], states[3]);
        SWAP(states[0], states[1]);
      } adjoint auto;
  }

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script, except
  // for manual optimizations indicated
  operation A2 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[3], states[1]);
        CNOT(states[1], states[0]);
        CNOT(states[0], states[2]);
        X(states[3]); // manual optimization
        CNOT(states[2], states[3]);

         X(states[1]);// manual optimization

        SWAP(states[0], states[3]);
        SWAP(states[0], states[1]);
        SWAP(states[0], states[2]);
         // X(states[1]); // moved for optimization
         // X(states[2]);
      } adjoint auto;
  }

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script
  operation A3 (states : Qubit []) : Unit {
    body (...){
        SWAP(states[1], states[2]);
        SWAP(states[0], states[3]);

      } adjoint auto;
  }

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script, except
  // for manual optimizations indicated
  operation A4 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[3], states[1]);
        CNOT(states[0], states[1]);
        X(states[2]); // X(states[3]);
        CNOT(states[1], states[2]);
        SWAP(states[2], states[3]);

         X(states[1]);
       //  X(states[3]);


      } adjoint auto;
  }

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script
  operation A5 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[1], states[0]);
        CNOT(states[2], states[1]);
        CNOT(states[3], states[2]);

        CNOT(states[2], states[3]);
        CNOT(states[1], states[2]);
        CNOT(states[0], states[1]);


         X(states[0]);
         X(states[1]);
         X(states[3]);


      } adjoint auto;
  }

  // # Summary
  // Affine operation for decomposition of the PRINCE S-box
  // Should match output of accompanying sage script
  operation A6 (states : Qubit []) : Unit {
    body (...){
        CNOT(states[0], states[3]);

        SWAP(states[0], states[1]);

         X(states[0]);
         X(states[3]);

      } adjoint auto;
  }

  // # Summary
  // Performs the PRINCE S-box, in-place, on 4 qubits
  // 
  // # References
  // Dušan Božilov and Miroslav Knežević and Ventzislav Nikov
  // https://eprint.iacr.org/2018/922
  operation FastSBox(nibble : Qubit[]) : Unit {
    body(...){
      A4(nibble);
      Q294(nibble);
      A3(nibble);
      Q294(nibble);
      A2(nibble);
      Q294(nibble);
      A1(nibble);
    } adjoint auto;
  }

  // # Summary
  // Inverts the PRINCE S-box, in-place, on 4 qubits
  // 
  // # References
  // Dušan Božilov and Miroslav Knežević and Ventzislav Nikov
  // https://eprint.iacr.org/2018/922
  operation FastSBoxInv(nibble : Qubit[]) : Unit {
    body(...){
      A6(nibble);
      Q294(nibble);
      A3(nibble);
      Q294(nibble);
      A2(nibble);
      Q294(nibble);
      A5(nibble);
    } adjoint auto;
  }

  // # Summary
  // Performs the PRINCE s-box, parallel and in-place,
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
  // Returns an array S such that S[i] will be the result of 
  // apply the S-box to an integer i (from 0 to 15).
  // SBoxInv returns the inverse SBox, i.e., SBoxInv()[SBox()[i]] = i
  function SBox () : Int[] {
    return  [11, 15, 3, 2, 10, 12, 9, 1, 6, 7, 8, 0, 14, 5, 13, 4];
  }
  function SBoxInv () : Int[] {
    return [11, 7, 3, 2, 15, 13, 8, 9, 10, 6, 4, 0, 5, 14, 12, 1];
  }

  // # Summary
  // Returns the RC constant for each round in Prince
  // 
  // # Inputs
  // ## index
  // Round number
  function RCConstant(index : Int) : BigInt {
    if (index == 0) {
      return 0L;
    } elif (index == 1) {
      return 0x13198a2e03707344L;
    } elif (index == 2) {
      return 0xa4093822299f31d0L;
    } elif (index == 3) {
      return 0x082efa98ec4e6c89L;
    } elif (index == 4) {
      return 0x452821e638d01377L;
    } elif (index == 5) {
      return 0xbe5466cf34e90c6cL;
    } elif (index == 6) {
      return 0x7ef84f78fd955cb1L;
    } elif (index == 7) {
      return 0x85840851f1ac43aaL;
    } elif (index == 8) {
      return 0xc882d32f25323c54L;
    } elif (index == 9) {
      return 0x64a51195e0e3610dL;
    } elif (index == 10) {
      return 0xd3b5a399ca0c2399L;
    } elif (index == 11) {
      return 0xc0ac29b7c97c50ddL;
    } else {
      return 0L;
    }
  }

  // # Summary
  // Extract a nibble from a BigInt
  function ExtractNibble(number: BigInt, nibble: Int) : BigInt {
    return (number >>> (4 * nibble)) % 16L;
  }

  // # Summary
  // Remove a given nibble from a BigInt
  function PunctureNibble(number: BigInt, nibble: Int) : BigInt {
    return number &&& (((1L <<< 64)-1L) ^^^ (15L <<< (4*nibble)));
  }

  // # Summary
  // Multiplies the matrix M' with a qubit state. Based on 
  // a PLU decomposition of the matrix.
  //
  // # Inputs
  // ## states
  // A 64-qubit state vector in Prince
  operation MatrixMPrimeMult(states : Qubit[]) : Unit {
    body (...){
      FanoutSwapReverseRegister(states);
      CNOT(states[4], states[0]);
      CNOT(states[8], states[0]);
      CNOT(states[9], states[1]);
      CNOT(states[13], states[1]);
      CNOT(states[6], states[2]);
      CNOT(states[14], states[2]);
      CNOT(states[7], states[3]);
      CNOT(states[11], states[3]);
      CNOT(states[8], states[4]);
      CNOT(states[12], states[4]);
      CNOT(states[9], states[5]);
      CNOT(states[13], states[5]);
      CNOT(states[10], states[6]);
      CNOT(states[15], states[7]);
      CNOT(states[12], states[8]);
      CNOT(states[14], states[10]);
      CNOT(states[15], states[11]);
      CNOT(states[20], states[16]);
      CNOT(states[24], states[16]);
      CNOT(states[21], states[17]);
      CNOT(states[25], states[17]);
      CNOT(states[26], states[18]);
      CNOT(states[30], states[18]);
      CNOT(states[23], states[19]);
      CNOT(states[31], states[19]);
      CNOT(states[28], states[20]);
      CNOT(states[25], states[21]);
      CNOT(states[29], states[21]);
      CNOT(states[26], states[22]);
      CNOT(states[30], states[22]);
      CNOT(states[27], states[23]);
      CNOT(states[28], states[24]);
      CNOT(states[29], states[25]);
      CNOT(states[31], states[27]);
      CNOT(states[36], states[32]);
      CNOT(states[40], states[32]);
      CNOT(states[37], states[33]);
      CNOT(states[41], states[33]);
      CNOT(states[42], states[34]);
      CNOT(states[46], states[34]);
      CNOT(states[39], states[35]);
      CNOT(states[47], states[35]);
      CNOT(states[44], states[36]);
      CNOT(states[41], states[37]);
      CNOT(states[45], states[37]);
      CNOT(states[42], states[38]);
      CNOT(states[46], states[38]);
      CNOT(states[43], states[39]);
      CNOT(states[44], states[40]);
      CNOT(states[45], states[41]);
      CNOT(states[47], states[43]);
      CNOT(states[52], states[48]);
      CNOT(states[56], states[48]);
      CNOT(states[57], states[49]);
      CNOT(states[61], states[49]);
      CNOT(states[54], states[50]);
      CNOT(states[62], states[50]);
      CNOT(states[55], states[51]);
      CNOT(states[59], states[51]);
      CNOT(states[56], states[52]);
      CNOT(states[60], states[52]);
      CNOT(states[57], states[53]);
      CNOT(states[61], states[53]);
      CNOT(states[58], states[54]);
      CNOT(states[63], states[55]);
      CNOT(states[60], states[56]);
      CNOT(states[62], states[58]);
      CNOT(states[63], states[59]);

      CNOT(states[55], states[63]);
      CNOT(states[59], states[63]);
      CNOT(states[54], states[62]);
      CNOT(states[49], states[61]);
      CNOT(states[53], states[61]);
      CNOT(states[48], states[60]);
      CNOT(states[52], states[60]);
      CNOT(states[56], states[60]);
      CNOT(states[51], states[59]);
      CNOT(states[50], states[58]);
      CNOT(states[49], states[57]);
      CNOT(states[53], states[57]);
      CNOT(states[48], states[56]);
      CNOT(states[51], states[55]);
      CNOT(states[50], states[54]);
      CNOT(states[39], states[47]);
      CNOT(states[34], states[46]);
      CNOT(states[38], states[46]);
      CNOT(states[33], states[45]);
      CNOT(states[37], states[45]);
      CNOT(states[41], states[45]);
      CNOT(states[36], states[44]);
      CNOT(states[40], states[44]);
      CNOT(states[35], states[43]);
      CNOT(states[34], states[42]);
      CNOT(states[38], states[42]);
      CNOT(states[33], states[41]);
      CNOT(states[32], states[40]);
      CNOT(states[35], states[39]);
      CNOT(states[32], states[36]);
      CNOT(states[23], states[31]);
      CNOT(states[18], states[30]);
      CNOT(states[22], states[30]);
      CNOT(states[17], states[29]);
      CNOT(states[21], states[29]);
      CNOT(states[25], states[29]);
      CNOT(states[20], states[28]);
      CNOT(states[24], states[28]);
      CNOT(states[19], states[27]);
      CNOT(states[18], states[26]);
      CNOT(states[22], states[26]);
      CNOT(states[17], states[25]);
      CNOT(states[16], states[24]);
      CNOT(states[19], states[23]);
      CNOT(states[16], states[20]);
      CNOT(states[7], states[15]);
      CNOT(states[11], states[15]);
      CNOT(states[6], states[14]);
      CNOT(states[1], states[13]);
      CNOT(states[5], states[13]);
      CNOT(states[0], states[12]);
      CNOT(states[4], states[12]);
      CNOT(states[8], states[12]);
      CNOT(states[3], states[11]);
      CNOT(states[2], states[10]);
      CNOT(states[1], states[9]);
      CNOT(states[5], states[9]);
      CNOT(states[0], states[8]);
      CNOT(states[3], states[7]);
      CNOT(states[2], states[6]);

      SWAP(states[58], states[62]);
      SWAP(states[55], states[59]);
      SWAP(states[48], states[52]);
      SWAP(states[43], states[47]);
      SWAP(states[36], states[40]);
      SWAP(states[33], states[37]);
      SWAP(states[27], states[31]);
      SWAP(states[20], states[24]);
      SWAP(states[17], states[21]);
      SWAP(states[10], states[14]);
      SWAP(states[7], states[11]);
      SWAP(states[0], states[4]);

      (Adjoint FanoutSwapReverseRegister)(states);
    }
    adjoint auto;
  }

// # Summary
// Computes the previous matrix, on the 48 first bits only
// That is, computes (M0,M1,M1)
  operation MatrixMPrimeFirst48(states : Qubit[]) : Unit {
    body (...){
      FanoutSwapReverseRegister(states);
      CNOT(states[20], states[16]);
      CNOT(states[24], states[16]);
      CNOT(states[21], states[17]);
      CNOT(states[25], states[17]);
      CNOT(states[26], states[18]);
      CNOT(states[30], states[18]);
      CNOT(states[23], states[19]);
      CNOT(states[31], states[19]);
      CNOT(states[28], states[20]);
      CNOT(states[25], states[21]);
      CNOT(states[29], states[21]);
      CNOT(states[26], states[22]);
      CNOT(states[30], states[22]);
      CNOT(states[27], states[23]);
      CNOT(states[28], states[24]);
      CNOT(states[29], states[25]);
      CNOT(states[31], states[27]);
      CNOT(states[36], states[32]);
      CNOT(states[40], states[32]);
      CNOT(states[37], states[33]);
      CNOT(states[41], states[33]);
      CNOT(states[42], states[34]);
      CNOT(states[46], states[34]);
      CNOT(states[39], states[35]);
      CNOT(states[47], states[35]);
      CNOT(states[44], states[36]);
      CNOT(states[41], states[37]);
      CNOT(states[45], states[37]);
      CNOT(states[42], states[38]);
      CNOT(states[46], states[38]);
      CNOT(states[43], states[39]);
      CNOT(states[44], states[40]);
      CNOT(states[45], states[41]);
      CNOT(states[47], states[43]);
      CNOT(states[52], states[48]);
      CNOT(states[56], states[48]);
      CNOT(states[57], states[49]);
      CNOT(states[61], states[49]);
      CNOT(states[54], states[50]);
      CNOT(states[62], states[50]);
      CNOT(states[55], states[51]);
      CNOT(states[59], states[51]);
      CNOT(states[56], states[52]);
      CNOT(states[60], states[52]);
      CNOT(states[57], states[53]);
      CNOT(states[61], states[53]);
      CNOT(states[58], states[54]);
      CNOT(states[63], states[55]);
      CNOT(states[60], states[56]);
      CNOT(states[62], states[58]);
      CNOT(states[63], states[59]);

      CNOT(states[55], states[63]);
      CNOT(states[59], states[63]);
      CNOT(states[54], states[62]);
      CNOT(states[49], states[61]);
      CNOT(states[53], states[61]);
      CNOT(states[48], states[60]);
      CNOT(states[52], states[60]);
      CNOT(states[56], states[60]);
      CNOT(states[51], states[59]);
      CNOT(states[50], states[58]);
      CNOT(states[49], states[57]);
      CNOT(states[53], states[57]);
      CNOT(states[48], states[56]);
      CNOT(states[51], states[55]);
      CNOT(states[50], states[54]);
      CNOT(states[39], states[47]);
      CNOT(states[34], states[46]);
      CNOT(states[38], states[46]);
      CNOT(states[33], states[45]);
      CNOT(states[37], states[45]);
      CNOT(states[41], states[45]);
      CNOT(states[36], states[44]);
      CNOT(states[40], states[44]);
      CNOT(states[35], states[43]);
      CNOT(states[34], states[42]);
      CNOT(states[38], states[42]);
      CNOT(states[33], states[41]);
      CNOT(states[32], states[40]);
      CNOT(states[35], states[39]);
      CNOT(states[32], states[36]);
      CNOT(states[23], states[31]);
      CNOT(states[18], states[30]);
      CNOT(states[22], states[30]);
      CNOT(states[17], states[29]);
      CNOT(states[21], states[29]);
      CNOT(states[25], states[29]);
      CNOT(states[20], states[28]);
      CNOT(states[24], states[28]);
      CNOT(states[19], states[27]);
      CNOT(states[18], states[26]);
      CNOT(states[22], states[26]);
      CNOT(states[17], states[25]);
      CNOT(states[16], states[24]);
      CNOT(states[19], states[23]);
      CNOT(states[16], states[20]);

      SWAP(states[58], states[62]);
      SWAP(states[55], states[59]);
      SWAP(states[48], states[52]);
      SWAP(states[43], states[47]);
      SWAP(states[36], states[40]);
      SWAP(states[33], states[37]);
      SWAP(states[27], states[31]);
      SWAP(states[20], states[24]);
      SWAP(states[17], states[21]);

    (Adjoint FanoutSwapReverseRegister)(states);
    }
    adjoint auto;
  }


  // Computes the M0 matrix of M'
  operation MatrixM0(states : Qubit[]) : Unit {
    body(...){
      FanoutSwapReverseRegister(states);
      CNOT(states[4], states[0]);
      CNOT(states[8], states[0]);
      CNOT(states[9], states[1]);
      CNOT(states[13], states[1]);
      CNOT(states[6], states[2]);
      CNOT(states[14], states[2]);
      CNOT(states[7], states[3]);
      CNOT(states[11], states[3]);
      CNOT(states[8], states[4]);
      CNOT(states[12], states[4]);
      CNOT(states[9], states[5]);
      CNOT(states[13], states[5]);
      CNOT(states[10], states[6]);
      CNOT(states[15], states[7]);
      CNOT(states[12], states[8]);
      CNOT(states[14], states[10]);
      CNOT(states[15], states[11]);
      CNOT(states[7], states[15]);
      CNOT(states[11], states[15]);
      CNOT(states[6], states[14]);
      CNOT(states[1], states[13]);
      CNOT(states[5], states[13]);
      CNOT(states[0], states[12]);
      CNOT(states[4], states[12]);
      CNOT(states[8], states[12]);
      CNOT(states[3], states[11]);
      CNOT(states[2], states[10]);
      CNOT(states[1], states[9]);
      CNOT(states[5], states[9]);
      CNOT(states[0], states[8]);
      CNOT(states[3], states[7]);
      CNOT(states[2], states[6]);

      SWAP(states[10], states[14]);
      SWAP(states[7], states[11]);
      SWAP(states[0], states[4]);

      (Adjoint FanoutSwapReverseRegister)(states);

    }
    adjoint auto;
  }

  // # Summary
  // Computes the M0 matrix of M', but only bits 4 to 15 are garanteed
  // to be correct
  operation MatrixM0_12(states : Qubit[]) : Unit {
    body(...){
      FanoutSwapReverseRegister(states);
      CNOT(states[4], states[0]);
      CNOT(states[8], states[0]);
      CNOT(states[9], states[1]);
      CNOT(states[13], states[1]);
      CNOT(states[6], states[2]);
      CNOT(states[14], states[2]);
      CNOT(states[7], states[3]);
      CNOT(states[11], states[3]);
      CNOT(states[8], states[4]);
      CNOT(states[12], states[4]);
      CNOT(states[9], states[5]);
      CNOT(states[13], states[5]);
      CNOT(states[10], states[6]);
      CNOT(states[15], states[7]);
      CNOT(states[12], states[8]);
      CNOT(states[14], states[10]);
      CNOT(states[15], states[11]);
      // CNOT(states[7], states[15]);
      // CNOT(states[11], states[15]);
      CNOT(states[6], states[14]);
      // CNOT(states[1], states[13]);
      // CNOT(states[5], states[13]);
      // CNOT(states[0], states[12]);
      // CNOT(states[4], states[12]);
      // CNOT(states[8], states[12]);
      CNOT(states[3], states[11]);
      // CNOT(states[2], states[10]);
      CNOT(states[1], states[9]);
      CNOT(states[5], states[9]);
      CNOT(states[0], states[8]);
      CNOT(states[3], states[7]);
      CNOT(states[2], states[6]);

      SWAP(states[10], states[14]);
      SWAP(states[7], states[11]);
      SWAP(states[0], states[4]);

      (Adjoint FanoutSwapReverseRegister)(states);

    }
    adjoint auto;
  }


  // # Summary
  // Shifts rows in a Prince cipher state
  //
  // # Inputs
  // ## qNibbles
  // A 64-bit state vector in Prince
  operation ShiftRow(qNibbles : Qubit[]) : Unit{
    body(...){
      NibbleSwap(0,12 ,qNibbles);
      NibbleSwap(0,8,qNibbles);
      NibbleSwap(0,4,qNibbles);
      NibbleSwap(1,9, qNibbles);
      NibbleSwap(2,6, qNibbles);
      NibbleSwap(2,10,qNibbles);
      NibbleSwap(2,14, qNibbles);
      NibbleSwap(5,13, qNibbles);
    }
    adjoint auto;
  }

  

  // # Summary
  // Part of the Simon function that only depend on the guesses
  // Requires Length(key0guesses) >= 16
  operation SimonPrinceSharedPart(key1 : Qubit[], key0guesses : Qubit[]) : Unit {
    body(...){
      //Fact( Length(key0guesses) >= 16, "Needs at least 16 bits of k_0 guess");
      let l = Length(key0guesses);
      BitWiseXor(key1[64-l...],key0guesses);
      // Constant = 0 at round 0
      let num_sboxes = l / 4;
      // Apply sboxes on all possible nibbles
      FastSBoxMulti(key0guesses[l-4*num_sboxes...]);
      if (Length(key0guesses) >= 16){
        let last4nibbles = key0guesses[l-16...];
        MatrixM0(last4nibbles);
        // Apply ShiftRow + Xoring in place
        let c = RCConstant(1);
        // Nibble 12 sent to nibble 8
        ApplyXorInPlaceL(ExtractNibble(c,8),LittleEndian(last4nibbles[0..3]));
        BitWiseXor(key1[32..35],last4nibbles[0..3]);
        // Nibble 13 sent to nibble 5
        ApplyXorInPlaceL(ExtractNibble(c,5),LittleEndian(last4nibbles[4..7]));
        BitWiseXor(key1[20..23],last4nibbles[4..7]);
        // Nibble 14 sent to nibble 2
        ApplyXorInPlaceL(ExtractNibble(c,2),LittleEndian(last4nibbles[8..11]));
        BitWiseXor(key1[8..11],last4nibbles[8..11]);
        // Nibble 15 left in place
        ApplyXorInPlaceL(ExtractNibble(c,15),LittleEndian(last4nibbles[12..15]));
        BitWiseXor(key1[60..63],last4nibbles[12..15]);
        // Sbox layer of round 2
        FastSBoxMulti(last4nibbles);
      }
    }
    adjoint auto;
  }

  // # Summary
  // Input-dependent operations that are missing in SimonPrinceSharedPart
  // Requires Length(key0guess) >= 16
  operation SimonPrinceRemainingFirstRounds(key1 : Qubit[], message : Qubit[], key0guessLength: Int) : Unit {
    body(...){
      Fact( key0guessLength >= 16, "Needs at least 16 bits of k_0 guess");
      BitWiseXor(key1[0..63-key0guessLength],message);
      // Constant = 0 at round 0
      let num_sboxes = key0guessLength / 4;
      // Apply sboxes on all nibbles not treated by SimonPrinceSharedPart
      FastSBoxMulti(message[0..63-4*num_sboxes]);
      MatrixMPrimeFirst48(message);
      ShiftRow(message);
      // Xor everywhere except on nibbles 2, 5, 8, 15
      let constant = 
        PunctureNibble(PunctureNibble(PunctureNibble(PunctureNibble(RCConstant(1),2),5),8),15);
      ApplyXorInPlaceL(constant, LittleEndian(message));
      BitWiseXor(key1[0..7],message[0..7]);
      FastSBoxMulti(message[0..7]);
      BitWiseXor(key1[12..19],message[12..19]);
      FastSBoxMulti(message[12..19]);
      BitWiseXor(key1[24..31],message[24..31]);
      FastSBoxMulti(message[24..31]);
      BitWiseXor(key1[36..59],message[36..59]);
      FastSBoxMulti(message[36..59]);
      // Remaining part of round 2
      MatrixMPrimeMult(message);
      ShiftRow(message);
      ApplyXorInPlaceL(RCConstant(2), LittleEndian(message));
      BitWiseXor(key1, message);      
    }
    adjoint auto;
  }  
  
  // # Summary
  // Computes the end of the first round, assuming the input-independent sboxes have
  // already been computed
  // Do not require key0guessLength >= 16
  operation SimonPrinceFirstRoundSmallGuess(key1 : Qubit[], message : Qubit[], key0guessLength: Int) : Unit {
    body(...){
      BitWiseXor(key1[0..63-key0guessLength],message);
      // Constant = 0 at round 0
      let num_sboxes = key0guessLength / 4;
      // Apply sboxes on all input-dependent nibbles
      FastSBoxMulti(message[0..63-4*num_sboxes]);
      MatrixMPrimeMult(message);
      ShiftRow(message);
      ApplyXorInPlaceL(RCConstant(1), LittleEndian(message));
      BitWiseXor(key1, message);
    }
    adjoint auto;
  }  


  // #Summary
  // Compute partially the last 2 rounds of Prince-core, up to a constant
  // Only correctly computes the output for bits 4..15
  operation SimonPrinceLast2Rounds(key : Qubit[], message : Qubit[]) : Unit {
    body(...){
        // Round 9
        BitWiseXor(key, message);
        ApplyXorInPlaceL(RCConstant(9), LittleEndian(message));
        (Adjoint ShiftRow)(message);
        // We could save a few CNOT here by only computing the values of nibbles 3, 6, 9, 12
        (Adjoint MatrixMPrimeMult)(message);
        // Apply S-box on nibbles 3, 6, 9, 12 only
        (Adjoint FastSBoxMulti)(message[12..15]+message[24..27]+message[36..39]+message[48..51]);
        // Round 10
        // Only nibbles 3, 6, 9, 12 are needed
        BitWiseXor(key[12..15],message[12..15]);
        BitWiseXor(key[24..27],message[24..27]);
        BitWiseXor(key[36..39],message[36..39]);
        BitWiseXor(key[48..51],message[48..51]);
        let c = RCConstant(10);
        ApplyXorInPlaceL(ExtractNibble(c,3),LittleEndian(message[12..15]));
        ApplyXorInPlaceL(ExtractNibble(c,6),LittleEndian(message[24..27]));
        ApplyXorInPlaceL(ExtractNibble(c,9),LittleEndian(message[36..39]));
        ApplyXorInPlaceL(ExtractNibble(c,12),LittleEndian(message[48..51]));
        // Mini ShiftRow
        NibbleSwap(0,12, message);
        NibbleSwap(1,9, message);
        NibbleSwap(2,6, message);
        // Mini M', computes only bits 4 to 15
        (MatrixM0_12)(message[0..15]);
        // Final sbox layer
        (Adjoint FastSBoxMulti)(message[4..15]);
        // Omit the final XORs
    }
    adjoint auto;
  }


  // # Summary
  // Compute bits 4 to 15 of encryption of Prince, up to a constant,
  // and assuming the input-independent part has already be computed
  // Requires key0guessLength >= 16
  //
  // # Inputs
  // ## key
  // 64 qubits for the key
  // ## message
  // 64 qubits for the input message, which is loosely transformed to the ciphertext
   operation SimonPrinceUnsharedPart(key : Qubit[], message : Qubit[], key0GuessLength: Int) : Unit {
    body(...){
      if (key0GuessLength < 16){
        SimonPrinceFirstRoundSmallGuess(key, message, key0GuessLength);
      } else {
        SimonPrinceRemainingFirstRounds(key,message,key0GuessLength);
      }
      let startRound = (key0GuessLength < 16) ? 2 | 3;
      for (idx in startRound..5){
        FastSBoxMulti(message);
        MatrixMPrimeMult(message);
        ShiftRow(message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        BitWiseXor(key, message);
      }
      FastSBoxMulti(message);
      MatrixMPrimeMult(message);
      (Adjoint FastSBoxMulti)(message);
      for (idx in 6..8){
        BitWiseXor(key, message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        (Adjoint ShiftRow)(message);
        (Adjoint MatrixMPrimeMult)(message);
        (Adjoint FastSBoxMulti)(message);
      }
      SimonPrinceLast2Rounds(key,message);
    }
    adjoint auto;
  }

  // # Summary
  // Same as SimonPrinceUnsharedPart, without any length requirement
  // and slightly more costly
   operation SimonPrinceSmallGuess(key : Qubit[], message : Qubit[],key0guessLength: Int) : Unit {
    body(...){
      SimonPrinceFirstRoundSmallGuess(key,message,key0guessLength);
      for (idx in 2..5){
        FastSBoxMulti(message);
        MatrixMPrimeMult(message);
        ShiftRow(message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        BitWiseXor(key, message);
      }
      FastSBoxMulti(message);
      MatrixMPrimeMult(message);
      (Adjoint FastSBoxMulti)(message);
      for (idx in 6..8){
        BitWiseXor(key, message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        (Adjoint ShiftRow)(message);
        (Adjoint MatrixMPrimeMult)(message);
       (Adjoint FastSBoxMulti)(message);
      }
      SimonPrinceLast2Rounds(key,message);
    }
    adjoint auto;
  }



  // # Summary
  // Encrypts a message in-place with the Prince permutation
  //
  // # Inputs
  // ## key
  // 64 qubits for the key
  // ## message
  // 64 qubits for the input message, which is transformed to the ciphertext
  operation PrinceEncrypt(key : Qubit[], message : Qubit[]) : Unit {
    body(...){
      BitWiseXor(key,message);
      ApplyXorInPlaceL(RCConstant(0), LittleEndian(message));
      for (idx in 1..5){
        FastSBoxMulti(message);
        MatrixMPrimeMult(message);
        ShiftRow(message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        BitWiseXor(key, message);
      }
      FastSBoxMulti(message);
      MatrixMPrimeMult(message);
      (Adjoint FastSBoxMulti)(message);
      for (idx in 6..10){
        BitWiseXor(key, message);
        ApplyXorInPlaceL(RCConstant(idx), LittleEndian(message));
        (Adjoint ShiftRow)(message);
        (Adjoint MatrixMPrimeMult)(message);
        (Adjoint FastSBoxMulti)(message);
      }
      ApplyXorInPlaceL(RCConstant(11), LittleEndian(message));
      BitWiseXor(key, message);
    }
    adjoint auto;
  }


  // # Summary
  // Computes a full Grover search iteration for an exhaustive key search against Prince,
  // with some number of messages
  // 
  // # Inputs
  // ## key
  // A 128-qubit key
  // ## messages
  // Some number of messages (length must be a multiple of 64)
  // ## phase
  // The state |->
  operation PrinceGrover(key : Qubit[], messages : Qubit[], phase : Qubit) : Unit {
    body(...){
      GroverOracle(64, key, messages, phase, PrinceGroverCipher, NoOp<Qubit[]>);
    }
    adjoint auto;
  }

  // # Summary
  // Formats an input of (Qubit[], Qubit[]) so that the Prince
  // cipher can apply to it
  operation PrinceGroverCipher(key : Qubit[], message : Qubit[]) : Unit {
    body (...){
      Prince(key[0..63], key[64..127], message);
    } adjoint auto;
  }

  // # Summary
  // Takes two halves of a prince key, and encrypts a message in-place.
  //
  // # Inputs
  // ## key0, key1
  // The two halves of the prince key
  // ## message
  // The input, which becomes the ciphertext
  operation Prince(key0 : Qubit[], key1 : Qubit[], message : Qubit[]) : Unit{
    body(...){
      Fact(Length(key0)==64, $"Key0 must be 64 bits; given {Length(key0)} bits");
      Fact(Length(key1)==64, $"Key1 must be 64 bits; given {Length(key1)} bits");
      Fact(Length(message)==64, $"Message must be 64 bits; given {Length(message)} bits");
      BitWiseXor(key0, message);
      PrinceEncrypt(key1, message);
      (Adjoint CyclicRotateRegister)(LittleEndian(key0));
      BitWiseXor(key0, message);
      CNOT(key0[62], message[0]);
      (CyclicRotateRegister)(LittleEndian(key0));

      // Same functionality as the previous 4 lines but only XORS key0 once
      // (CyclicRotateRegister)(LittleEndian(message));
      // CNOT(message[63], message[1]);
      // BitWiseXor(key0, message);
      // CNOT(message[63], message[1]);
      // (Adjoint CyclicRotateRegister)(LittleEndian(message));
    } adjoint auto;
  }



  // # Summary
  // Computes the permutation and copies out the result to act as the function f in the offline Simon attack.
  // Does not include any optimizations
  //
  // # Inputs
  // ## key1Guesses
  // 64 Qubits for the permutation key, which is searched over
  // ## xs
  // Qubits representing "x", the portion of the state on which Simon's algorithm is run
  // ## keyGuesses
  // Qubits representing "i", the portion of the state that is being exhaustively searched
  // ## outputs
  // outputs
  // Qubits to copy the result onto
  operation SimonFunctionF(key1Guesses : Qubit[], xs : Qubit[], key0Guesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...){
      PrinceEncrypt(key1Guesses, xs + key0Guesses);
      for (idx in 0.. Length(outputs) - 1){
        CNOT((xs+key0Guesses)[idx], outputs[idx]);
      }
      (Adjoint PrinceEncrypt)(key1Guesses, xs + key0Guesses);
    }
  }

  // # Summary
  // Same functionality as SimonFunctionF, except it is only guaranteed to compute `outputLength` bits
  // correctly before output.
  //
  // # Inputs
  // ## outputLength
  // Number of output bits to correctly compute and output. Must be at most 12 bits.
  // ## key1Guesses
  // 64 qubits for the permutation key
  // ## xs
  // Qubits representing "x", the portion of the state on which Simon's algorithm is run
  // ## keyGuesses
  // Qubits representing "i", the portion of the state that is being exhaustively searched. 
  // If there are fewer than 16 qubits here, it will use a different method for the unshared part
  // ## outputs
  // Qubits to copy the result onto
  operation SimonFunctionFUnsharedPart (outputLength: Int, key1Guesses : Qubit[], xs : Qubit[], key0Guesses : Qubit[], outputs : Qubit[]) : Unit {
    body (...){
      Fact(outputLength <= 12, "Output length can be at most 12 bits");
      let key0GuessLength = Length(key0Guesses);
      SimonPrinceUnsharedPart(key1Guesses, xs + key0Guesses, key0GuessLength);
      for (idx in 0..outputLength-1){
        CNOT((xs+key0Guesses)[4+idx], outputs[idx]);
      }
      (Adjoint SimonPrinceUnsharedPart)(key1Guesses, xs + key0Guesses, key0GuessLength);
    }
  }
  



  // # Summary
  // Tests the Prince cipher according to the 4 test vectors
  // from the specification.
  // Also checks that the truncated version computes the correct value on these vectors
  @Test("ToffoliSimulator")
  operation PrinceTest() : Unit {
    let plainTexts = [0x0000000000000000L,0xffffffffffffffffL,0L,0L,0x0123456789abcdefL];
    let key0s = [0L, 0L, 0xffffffffffffffffL,0L, 0L];
    let key1s = [0L, 0L, 0L,0xffffffffffffffffL, 0xfedcba9876543210L];
    let cipherTexts = [0x818665aa0d02dfdaL,0x604ae6ca03c20adaL,0x9fb51935fc3df524L,0x78a54cbe737bb7efL,0xae25ad3ca8fa9ccfL];
    for (idx in 0..4){
       using ((message,message2, key0, key1)=(Qubit[64], Qubit[64], Qubit[64], Qubit[64])){
        ApplyXorInPlaceL(key0s[idx], LittleEndian(key0));
        ApplyXorInPlaceL(key1s[idx], LittleEndian(key1));
        ApplyXorInPlaceL(plainTexts[idx], LittleEndian(message));
        BitWiseXor(message, message2);
        // Compute truncated variant with a shared part
        let k0guesslen = 23;
        BitWiseXor(key0,message2);
        SimonPrinceSharedPart(key1, message2[64-k0guesslen..63]);
        SimonPrinceUnsharedPart(key1, message2, k0guesslen);
        ApplyXorInPlaceL(RCConstant(11), LittleEndian(message2));
        BitWiseXor(key1, message2);
        (Adjoint CyclicRotateRegister)(LittleEndian(key0));
        BitWiseXor(key0, message2);
        CNOT(key0[62], message2[0]);
        CyclicRotateRegister(LittleEndian(key0));      
        // End Compute
        Prince(key0, key1, message);
        // xor the 2 messages, for comparison
        BitWiseXor(message,message2);
        let resultCipher = MeasureBigInteger(LittleEndian(message));
        let TruncCipher = MeasureBigInteger(LittleEndian(message2[4..15]));
        Fact(resultCipher==cipherTexts[idx], $"Encrypted {plainTexts[idx]} with {key0s[idx]}, {key1s[idx]}. Expected {cipherTexts[idx]}, got {resultCipher}");
        Fact(TruncCipher == 0L, "Truncated variant does not match reference implementation");
        ResetAll(key0);
        ResetAll(key1);
        ResetAll(message);
        ResetAll(message2);
      }
    }
  }


  // # Summary
  // Checks that the optimized variants computes the same thing as
  // the reference implementation for random message, key, guess size
  @Test("ToffoliSimulator")
  operation OptimizedPrinceTest() : Unit {
    for(idx in 0..4) {
      using ((message1, message2, message3, key, outputs, outputs2) = (Qubit[64], Qubit[64],Qubit[64], Qubit[64], Qubit[12], Qubit[12])) {
        // Pick random message & key
        let testInt = RandomBigInt(2L^64);
        let testKey = RandomBigInt(2L^64);
        // Write into quantum registers
        ApplyXorInPlaceL(testInt, LittleEndian(message1));
        ApplyXorInPlaceL(testInt, LittleEndian(message2));
        ApplyXorInPlaceL(testInt, LittleEndian(message3));
        ApplyXorInPlaceL(testKey, LittleEndian(key));
        // Compute with the full circuit
        PrinceEncrypt(key, message1);
        // Randomized guess length
        let guesslength = DrawRandomInt(16,64);
        SimonPrinceSharedPart(key,message2[64-guesslength...]);
        SimonFunctionFUnsharedPart(12, key, message2[0..63-guesslength], message2[64-guesslength...], outputs);
        let guesslength2 = DrawRandomInt(0,15);
        SimonPrinceSharedPart(key,message3[64-guesslength2...]);
        SimonFunctionFUnsharedPart(12, key, message3[0..63-guesslength2], message3[64-guesslength2...], outputs2);
        // Linear part omitted in SimonFunctionFUnsharedPart
        ApplyXorInPlaceL(RCConstant(11), LittleEndian(message1));
        ApplyXorInPlaceL(testKey, LittleEndian(message1));
        // Measures bits 4..15 from the full circuit
        let resultInt = MeasureBigInteger(LittleEndian(message1[4..15]));
        //Measures the output from the truncated circuit
        let truncatedInt = MeasureBigInteger(LittleEndian(outputs));
        let truncatedInt2 = MeasureBigInteger(LittleEndian(outputs2));

        Fact(resultInt == truncatedInt, $"Optimized Prince failed on input {testInt}, key {testKey}, length {guesslength}: found {truncatedInt}, should have {resultInt}");
        Fact(truncatedInt2 == truncatedInt, $"Small length optimized Prince failed on input {testInt}, key {testKey}, length {guesslength2}: found {truncatedInt2}, should have {truncatedInt}");

        ResetAll(message1 + message2 + message3 + key + outputs);
      }
    }
  }

  // # Summary
  // Tests that the fast S-box function matches
  // the pre-computed arrays
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
        FastSBoxInv(states);
        let result = MeasureBigInteger(LittleEndian(states));
        Fact(result == IntAsBigInt(sboxinv[idx]), $"Failed on {idx}, returned {result}");
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