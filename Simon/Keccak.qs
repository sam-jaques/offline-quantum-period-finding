
namespace Quantum.Keccak
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
  open Microsoft.Quantum.Arrays;
  open Quantum.BlockCipherBasics;

  open Microsoft.Quantum.ModularArithmetic.DebugHelpers;


  // # Summary
  // Type to represent Keccak states.
  // This is really just a qubit array but since it is 
  // indexed as a 3-dimensional array this type-checks 
  // to avoid indexing errors.
  newtype KeccakState = (qubits: Qubit[], length : Int);

  // # Summary
  // Returns an array that gives the inverse of the "S-box" of the Chi function
  function SBoxInv() : Int[] {
    return [0, 11, 22, 9, 13, 4, 18, 15, 26, 1, 8, 3, 5, 12, 30, 7, 21, 20, 2, 23, 16, 17, 6, 19, 10, 27, 24, 25, 29, 28, 14, 31];
  }

  // # Summary
  // Keccak states are 3-dimensional, indexed by 
  // x in [0..4],y in [0..4],z in [0.. w - 1], but this 
  // namespace represents them as a 1-dimensional array.
  // This function returns the index of a three-dimensional index
  // 
  // # Inputs
  // ## x,y,z
  // The indices of the qubit
  // ## w
  // The LEngth
  function FlattenKeccak(x : Int, y : Int, z : Int, states : KeccakState) : Qubit {
    return states::qubits[y*states::length*5 + x*states::length + z];
  }


  // # Summary
  // Keccak states a 3-dimensional array, but here they are represented
  // as a 1-dimensional qubit array, such that a contiguous range
  // such as 0..8 represents a range of z values, but fixed x and y.
  // The S-box in Chi applies to a range of x-values for fixed z and y
  // Thus, to apply Chi more naturally requires re-indexing the array.
  function ShortState(length : Int, states : KeccakState) : Qubit[] {
    // we want to fix z,y, and iterate over x
    let newStates = ChiRearrange(states);
    return newStates[0..length -1];
  }
  


  operation TestRoundConstants() : Unit {
    let test = RoundConstants(18, 8);
  }

  // # Summary
  // Returns an array of all the round constants needed to apply Keccak.
  // 
  // # Inputs
  // ## nRounds
  // The number of rounds of the permutation
  // ## length
  // The lengt of the z index (so blocks have 25 * length bits)
  //
  // # Notes
  // The full round constant computation is a work-in-progress, so it
  // only supports length = 8, using hard-coded bitstrings
  function RoundConstants(nRounds : Int, length : Int) : BigInt[] {
  //  Fact(nRounds == 18 and length == 8, "Currently only supports 5*5*8-bit permutations");
    let realRoundCounstants =  [0x01L, 0x82L, 0x8aL, 0x00L, 0x8bL, 0x01L, 0x81L, 0x09L, 0x8aL,
                                0x88L, 0x09L, 0x0aL, 0x8bL, 0x8bL, 0x89L, 0x03L, 0x02L, 0x80L];
    // TODO:
    mutable r = new Bool[8];
    set r w/= 0 <- true;
    mutable rs = new Bool[255];
    set rs w/= 0 <- true;
    for (idt in 1..254){
      set r = [false] + r;
      set r w/= 0 <- Microsoft.Quantum.Logical.Xor(r[0], r[8]);
      set r w/= 4 <- Microsoft.Quantum.Logical.Xor(r[4], r[8]);
      set r w/= 5 <- Microsoft.Quantum.Logical.Xor(r[5], r[8]);
      set r w/= 6 <- Microsoft.Quantum.Logical.Xor(r[6], r[8]);
      set r = r[0..7];
      set rs w/= idt <- r[0];
  //    Message($"t = {idt}, r = {r}");
    }
   // Message($"RS: {rs}");
    let logLength = BitLength(length);
    mutable roundConstants = new BigInt[nRounds];
    for (idi in 0..nRounds - 1){
      mutable roundConstant = new Bool[length];
      for (idj in 0..logLength){
        set roundConstant w/= 2^idj - 1 <- rs[(idj + 7*idi)%254];
      }
      // This is incorrect: it needs to spread the bits around in a tricky way
      // Needs an extra element so it doesn't treat it as a sign?
      set roundConstants w/= idi <- BoolArrayAsBigInt(roundConstant +[false]);
      // Message($"Round {idi}, constant = {roundConstants[idi]}");
      // Message($"    Actual: {realRoundCounstants[idi]}");
    }
    return roundConstants;
  }

  // # Summary
  // Applies the non-linear Chi transformation, out-of-place,
  // to 5 bits (imagined to be the (0,y,z),...,(4,y,z) for some
  // y and z).
  //
  // # Inputs
  // ## states
  // 5 qubits which are the input
  // ## spareState
  // 5 qubits assumed to be in the state |00000>, which will be returned
  // with Chi(states)
  operation OneBlockChi(states : Qubit[], spareStates : Qubit[]) : Unit {
    body (...){
        X(states[0]);
        X(states[2]);
        AndWrapper(states[0], states[1], spareStates[4]); 
        AndWrapper(states[2], states[3], spareStates[1]); 
        X(states[0]);
        X(states[2]);
        X(states[1]);
        X(states[3]);
        AndWrapper(states[1], states[2], spareStates[0]); 
        AndWrapper(states[3], states[4], spareStates[2]); 
        X(states[1]);
        X(states[3]);
        X(states[4]);
        AndWrapper(states[0], states[4], spareStates[3]); 
        X(states[4]);
        for (idx in 0..4) {
          CNOT(states[idx], spareStates[idx]);
        }
      } adjoint auto;
  }

  // # Summary
  // Applies the non-linear Chi transformation, out-of-place.
  // Requires a true Keccak state for the indexing to work properly,
  // since the x bits (each of which are input to the S-bix)
  // are non-contiguous
  operation ChiForward(states : KeccakState, spareStates : KeccakState) : Unit {
    body (...){
      for (idy in 0..4) {
        for (idz in 0.. states::length - 1){
          let statesXQubit = FlattenKeccak(_, idy, idz, states);
          let sparesXQubit = FlattenKeccak(_, idy, idz, spareStates);
          OneBlockChi([statesXQubit(0), statesXQubit(1), statesXQubit(2), statesXQubit(3), statesXQubit(4)],
            [sparesXQubit(0), sparesXQubit(1), sparesXQubit(2), sparesXQubit(3), sparesXQubit(4)]);
        }
      }
    }
    adjoint auto;
  }

  // # Summary  
  // Inverse of the non-linear transformation of the Chi function,
  // as a 5-bit S-box.
  // 
  // # Inputs
  // ## states
  // 5 qubits which are the input
  // ## spareState
  // 5 qubits assumed to be in the state |00000>, which will be returned
  // with Chi^{-1}(states)
  //
  // # Reference
  // Based on https://github.com/KeccakTeam/KeccakTools/blob/master/Sources/Keccak-f.h
  operation FastSBoxInv(states : Qubit[], spareStates : Qubit[]) : Unit {
    body (...){
        X(states[1]);
        AndWrapper(states[2],states[1], spareStates[0]);
        X(states[1]);
        CNOT(states[0], spareStates[0]);

        X(states[4]);
        AndWrapper(spareStates[0],states[4], spareStates[3]);
        X(states[4]);
        CNOT(states[3], spareStates[3]);


        X(states[2]);
        AndWrapper(spareStates[3],states[2], spareStates[1]);
        X(states[2]);
        CNOT(states[1], spareStates[1]);

        X(states[0]);
        AndWrapper(spareStates[1],states[0], spareStates[4]);
        X(states[0]);
        CNOT(states[4], spareStates[4]);

        X(states[3]);
        AndWrapper(spareStates[4],states[3], spareStates[2]);
        X(states[3]);

        //?? bizarre bonus round
        X(states[1]);
        CCNOT(spareStates[2],states[1], spareStates[0]);
        CNOT(states[2], spareStates[2]);
        X(states[1]);     

      } adjoint auto;
  }

  // # Summary
  // Applies the inverse of the Chi permutation, out-of-place
  // 
  operation ChiBackward(states : KeccakState, spareStates : KeccakState) : Unit {
    body (...){
      let chiOrderedStates = ChiRearrange(states);
      let chiOrderedSpareStates = ChiRearrange(spareStates);
      for (idx in 0..5..Length(chiOrderedStates) - 1){
        FastSBoxInv(chiOrderedStates[idx..idx+4], chiOrderedSpareStates[idx..idx+4]);
      }
    }
    adjoint auto;
  }

   // # Summary
  // Keccak states a 3-dimensional array, but here they are represented
  // as a 1-dimensional qubit array, such that a contiguous range
  // such as 0..8 represents a range of z values, but fixed x and y.
  // The S-box in Chi applies to a range of x-values for fixed z and y
  // Thus, to apply Chi more naturally requires re-indexing the array
  function ChiRearrange(states : KeccakState) : Qubit[] {
    mutable outputStates = new Qubit[0];
    for (idy in 0..4) { 
      for (idz in 0..states::length - 1){
          for (idx in 0..4){
            set outputStates = outputStates + [FlattenKeccak(idx, idy, idz, states)];
          }
      }
    }
    return outputStates;
  }

  // # Summary
  // Applies the non-linear function Chi
  operation Chi(states : KeccakState) : Unit {
    body (...){
      using (spareStates = Qubit[Length(states::qubits)]){
        let spareKeccak = KeccakState(spareStates, states::length);
        ChiForward(states, spareKeccak);
        // At this point `states` contains the original state
        // and `spareStates` contains the S-box transformation.
        // Equivalently, `states` contains the inverse S-box transformation
        // of `spareStates`, so uncomputing the inverse will clear the qubits in 
        // `states` to |0>
        (Adjoint ChiBackward)(spareKeccak, states);
        for (idx in 0..Length(states::qubits) - 1){
          SWAP(states::qubits[idx], spareStates[idx]);
        }
      }
    }
    adjoint auto;
  }

  operation KeccakRound(roundConstant : BigInt, states : KeccakState) : Unit {
    body (...) {
      PiRhoTheta(states);
      Chi(states);
      // Iota is actually just an in-place XOR of an 8-bit round constant:
      ApplyXorInPlaceL(roundConstant, LittleEndian(states::qubits[0..7]));
    }
    adjoint auto;
  }

  operation Keccak(nRounds : Int, states : Qubit[]) : Unit{
    body (...){
      let blockSize = Length(states)/25;
      let length = BitLength(blockSize);
      let roundConstants = RoundConstants(nRounds, blockSize);
      for (idx in 0..nRounds -1){
        KeccakRound(roundConstants[idx], KeccakState(states, blockSize));
      }
    }
    adjoint auto;
  }

  // # Summary
  // Computes correctly the first 15 bits, up to a constant
  operation SimonKeccak(nRounds : Int, states : Qubit[]) : Unit{
    body (...){
      let blockSize = Length(states)/25;
      let length = BitLength(blockSize);
      let roundConstants = RoundConstants(nRounds, blockSize);
      for (idx in 0..nRounds-2){
        KeccakRound(roundConstants[idx], KeccakState(states, blockSize));
      }
      PiRhoTheta(KeccakState(states, blockSize));

      // Chi for last round; needs re-indexing
      let shortStates = ShortState(15, KeccakState(states, blockSize));
      using (spareStates = Qubit[15]){
        for (idx in 0..5..14){
          OneBlockChi(shortStates[idx..idx+4], spareStates[idx..idx+4]);
          (Adjoint FastSBoxInv)(spareStates[idx..idx+4], shortStates[idx..idx+4]);
        }
        for (idx in 0..14){
          SWAP(shortStates[idx], spareStates[idx]);
        }
      }
    }
    adjoint auto;
  }

  // # Summar
  // Tests that Keccak doesn't leave qubits in a funny state
  // Does not test correctness
  @Test("ToffoliSimulator")
  operation KeccakTest() : Unit {
    body (...){
      let blockSize = 8;
      let nRounds = 12 + 2 * 3; // 3 = lg(8)
      using (states = Qubit[5*5*blockSize]) {
        Keccak(nRounds, states);
        ResetAll(states);
      }
    }
  }

  // # Summary
  // Tests the Keccak "S-box" inverse (i.e., Chi)
  @Test("ToffoliSimulator")
  operation KeccakSBoxTest() : Unit{
    using (states = Qubit[10]){
      let sboxinv = SBoxInv();
      for (idx in 0..31){
        ApplyXorInPlace(idx, LittleEndian(states));
        FastSBoxInv(states[0..4], states[5..9]);
        let result = MeasureBigInteger(LittleEndian(states[5..9]));
        let input = MeasureBigInteger(LittleEndian(states[0..4]));
        Fact(result == IntAsBigInt(sboxinv[idx]), $"Failed on optimized {idx}, returned {result}");
      }
    }
  }
  
}