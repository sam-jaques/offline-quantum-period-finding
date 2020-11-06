// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


// Wrappers to allocate qubits, call the required functions, then release the qubits

namespace SimonResourceWrappers
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
    open Quantum.Chaskey;
    open Quantum.Prince;
    open Quantum.Keccak;
    open Quantum.Elephant;



    operation ClearRegister(register:Qubit[]):Unit {
        for (idx in 0..Length(register)-1){
            AssertMeasurementProbability([PauliZ],[register[idx]],Zero,0.0,"n/a",0.5);
        }	
        ResetAll(register);
    }

    operation CCNOTResourceEstimate(nQubits : Int, isControlled : Bool) : Unit {
        using (qubits = Qubit[3]){
            CCNOT(qubits[0], qubits[1], qubits[2]);
            ClearRegister(qubits);
        }
    }

    operation ControlledOp<'T>(isControlled : Bool, op : ('T => Unit is Ctl), parameters : 'T) : Unit {
        if (isControlled){
            using (controls = Qubit[1]){
                (Controlled op)(controls, (parameters));
                ClearRegister(controls);
            }
        } else {
            op(parameters);
        }
    }

    operation LookUpTimingResourceEstimate(nQubits : Int, isControlled : Bool) : Unit {
        if (nQubits < 25){
            using ((addressQubits, outputQubits) = (Qubit[nQubits], Qubit[nQubits])){
                let valueTable = Microsoft.Quantum.Arrays.ForEach(RandomBoundedBigInt(_, 2L^nQubits - 1L ), new BigInt[2^nQubits]);
                let value = LittleEndian(outputQubits);
                let address = LittleEndian(addressQubits);
                ControlledOp<(BigInt[], (BigInt => Unit is Ctl + Adj), LittleEndian)>
                    (isControlled, EqualLookup<BigInt>, (valueTable, ApplyXorInPlaceL(_, value), address));
                ClearRegister(addressQubits + outputQubits);
            }
        }
    }

    // Estimates the resources required to compute the rank of a matrix
    operation RankResourceEstimate(width : Int, height : Int, isControlled : Bool) : Unit {
        using (matrixQubits = Qubit[width * height]){
            let matrix = QubitArrayAsMatrix(width, height, matrixQubits);
            using (checkQubit = Qubit[1]){
                ControlledOp(isControlled, IsFullRank, (matrix, checkQubit[0]));
                ClearRegister(checkQubit);
            }
            ClearRegister(matrixQubits);
        }
    }

    // Estimates for the full encryption
    operation ChaskeyGroverEstimate(rounds : Int, nMessages : Int, isControlled : Bool) : Unit {
        // Needs two blocks!
        using ((messages, key, phase) = (Qubit[128*nMessages], Qubit[128], Qubit())){
            ChaskeyGrover(rounds, key, messages, phase);
            ClearRegister(messages + key + [phase]);
        }
    }

   operation PrinceGroverEstimate(length :Int, nMessages : Int, isControlled : Bool) : Unit {
        // Needs 3 blocks
        using ((messages, key, phase) = (Qubit[64*nMessages], Qubit[128], Qubit())){
            PrinceGrover(key, messages, phase);
            ClearRegister(messages + key + [phase]);
        }
   }

   operation ElephantGroverEstimate(length : Int, nMessages : Int, isControlled : Bool) : Unit {
        using ((messages, key, phase) = (Qubit[2*length*nMessages], Qubit[length], Qubit())){
            ElephantGrover(length, key, messages, phase);
            ClearRegister(messages + key + [phase]);
        }
   }

   // Estimates for truncated and optimized Simon function
   operation ChaskeyAttackEstimate(rounds : Int, guessSize : Int, isControlled : Bool) : Unit {
        using ((messageQubits, outputs) = (Qubit[128], Qubit[11])){
            Quantum.Chaskey.SimonFunctionFUnsharedPart(rounds, 11, messageQubits[0..guessSize - 1], messageQubits[guessSize .. 127], outputs);
            ClearRegister(messageQubits);
        }
   }

   operation PrinceAttackEstimate(uselessInt : Int, guessSize : Int, isControlled : Bool) : Unit {
        using ((messageQubits, keyQubits, outputs) = (Qubit[64], Qubit[64], Qubit[11])){
            Quantum.Prince.SimonFunctionFUnsharedPart(11, keyQubits, messageQubits[0..guessSize - 1], messageQubits[guessSize..63], outputs);
            ClearRegister(messageQubits + keyQubits);
        }
   }

    operation ElephantAttackEstimate(length : Int, guessSize : Int, isControlled : Bool) : Unit {
        let outputLength = 11;
        using ((messageQubits, outputs) = (Qubit[length], Qubit[outputLength])){
            Quantum.Elephant.SimonFunctionFUnsharedPart(outputLength, length, messageQubits[0..guessSize - 1], messageQubits[guessSize .. length - 1], outputs);
            ClearRegister(messageQubits);
        }
   }

   // Estimates for non-optimized Simon function
   operation FullChaskeyAttackEstimate(rounds : Int, isControlled : Bool) : Unit {
        using ((messageQubits, outputs) = (Qubit[128], Qubit[11])){
            Quantum.Chaskey.SimonFunctionF(rounds, messageQubits[0..64], messageQubits[65..127], outputs);
            ClearRegister(messageQubits);
        }
   }
   operation FullPrinceAttackEstimate(uselessInt : Int, isControlled : Bool) : Unit {
        using ((messageQubits, keyQubits, outputs) = (Qubit[64], Qubit[64], Qubit[11])){
            Quantum.Prince.SimonFunctionF(keyQubits, messageQubits[0..32], messageQubits[33..63], outputs);
            ClearRegister(messageQubits + keyQubits);
        }
   }

   operation FullElephantAttackEstimate(length : Int, isControlled : Bool) : Unit {
        using ((messageQubits, outputs) = (Qubit[length], Qubit[11])){
            Quantum.Elephant.SimonFunctionF(length, messageQubits[0..64], messageQubits[65..length - 1], outputs);
            ClearRegister(messageQubits);
        }
   }
}
