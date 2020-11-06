from plu_decomposition import *


# Transforms a permutation P into a sequence of transpositions
# and prints them out as a sequence of Q# operations on a qubit array
# called `bufname`
def PermutationToSwap(P, bufname="state", tabs=0, spaces=4):
    code = ""
    tab = (" " * spaces) if spaces > 0 else "\t"
    cycles = map(CycleToTranspositions, P.to_cycles(singletons=False))
    cycles = [e for sub in cycles for e in sub]
    for c in cycles[::-1]: # apply cycles right to left
        l, r = c[0]-1, c[1]-1 # sage Permutations work on {1..n}, so had to shift up indices
        code += '%sSWAP(%s[%d], %s[%d]);\n' % (tab * tabs, bufname, l, bufname, r)
    return code

# Returns an integer < 16 as an array of {0,1} 
def IntToBits(someInt):
    bits = someInt.digits(2)
    return bits + [0]*(4-len(bits));

# Transforms an affine transformation
# into a series of CNOTs, Swaps, and then X gates
def AffineToCNOTs(A, n):
    A_array = [];
    # The image of the canonical basis vectors under A,
    # obtained by removing the constant, which must be A[0]
    for i in range(n):
        A_array += IntToBits(A[2^i] ^^ A[0])
    # Build a matrix out of the action on basis vectors
    A_matrix = matrix(F,4,A_array)
    A_matrix = A_matrix.transpose()
    # PLU decompose and print the result
    P, L, U = A_matrix.LU()
    code = ""
    code += UpperTriangularToCNOT(U, "states", 2, 4, false) + "\n"
    code += LowerTriangularToCNOT(L, "states", 2, 4, false) + "\n"
    code += PermutationToSwap(MatrixToPermutation(P), "states", 2, 4) + "\n"
    # Print the constant
    for i in range(4):
        if IntToBits(A[0])[i]:
            code += "         X(states[" + str(i) + "]);\n"
    return code

print ("=====================PRINCE=======================")
# Computes the Prince matrix Mprime
F = GF(2);
m0 = matrix(F,4,[0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1])
m1 = matrix(F,4,[1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1])
m2 = matrix(F,4,[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1])
m2 = matrix(F,4,[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1])
m3 = matrix(F,4,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0])
M0 = block_matrix([[m0,m1,m2,m3],[m1,m2,m3,m0],[m2,m3,m0,m1],[m3,m0,m1,m2]],subdivide=false)
M1 = block_matrix([[m1,m2,m3,m0],[m2,m3,m0,m1],[m3,m0,m1,m2],[m0,m1,m2,m3]],subdivide=false)
Mz = matrix(F,16)
Mprime = block_matrix([[M0,Mz,Mz,Mz],[Mz,M1,Mz,Mz],[Mz,Mz,M1,Mz],[Mz,Mz,Mz,M0]],subdivide=false)
P, L, U = Mprime.LU()

#Print the matrix M_prime
print UpperTriangularToCNOT(U, "states", 2, 4, false);
print LowerTriangularToCNOT(L, "states", 2, 4, false);
print PermutationToSwap(MatrixToPermutation(P), "states", 2, 4);





# Prints the affine transformations for the fast S-box
# Affine matrices from Bozilov et al:
As = [  [0xC,0xE,7,5,8,0xA,3,1,4,6,0xF,0xD,0,2,0xB,9],
        [6,0xD,9,2,5,0xE,0xA,1,0xB,0,4,0xF,8,3,7,0xC],
        [0,8,4,0xc,2,0xa,6,0xe,1,9,5,0xd,3,0xb,7,0xf],
        [0xa,1,0,0xb,2,9,8,3,4,0xf,0xe,5,0xc,7,6,0xd],
        [0xb,8,0xe,0xd,1,2,4,7,0xf,0xc,0xa,9,5,6,0,3],
        [9,3,8,2,0xd,7,0xc,6,1,0xb,0,0xa,5,0xf,4,0xe]]
for A in As:
    print("----- A------")
    print AffineToCNOTs(A, 4)



print ("=====================ELEPHANT====================")
# P layers
print("-----------160 bit P layer-------------");
P = Permutation([(40 * x % 159)+1 for x in range(159)])
print(P)
print PermutationToSwap(P, "states", 2, 4);
print("-----------176 bit P layer-------------");
P = Permutation([(44 * x % 175)+1 for x in range(175)])
print PermutationToSwap(P, "states", 2, 4);
print("-----------Sbox------------");
As = [  [0xD,2,0xB,4,3,0xC,5,0xA,0xE,1,8,7,0,0xF,6,9],
        [0,8,3,0xB,4,0xC,7,0xF,1,9,2,0xA,5,0xD,6,0xE],
        [1,0,0xB,0xA,8,9,2,3,7,6,0xD,0xC,0xE,0xF,4,5],]

for A in As:
    print("----- A------")
    print AffineToCNOTs(A, 4)



print ("=====================KECCAK====================")

def FlattenKeccak(x, y, z, w):
    return y*w*5 + x*w + z

def RaiseKeccak(t, w):
    return [int( (t % 5*w)/w), int(t/(5*w)), t % w]

def PiRotate(n):
	i = int(n/5)
	j = n % 5
	return ((3*i+2*j)%5)*5 + i

# For other Keccak block sizes, alter this:
w = (200/25)
w = 64

# Computes theta as a matrix
theta = matrix.identity(F,25*w)

for x in range(5):
    for z in range(w):
        for y in range(5):
            row = FlattenKeccak(x,y,z,w)
            for y2 in range(5):
                theta[row, FlattenKeccak((x+4)%5,y2,z,w)] += 1
                theta[row, FlattenKeccak((x+1)%5,y2,(z-1)%w,w)] += 1

# Computes Rho as a permutation
# by first building it as a dictionary
# then turning that to a permutation
x = 1
y = 0
rhoDict = dict()
for t in range(24):
    for z in range(w):
        rhoDict[FlattenKeccak(x,y,z,w)] = FlattenKeccak(x,y,(z-(t+1)*(t+2)/2)%w,w)
    x, y = y, (2*x+3*y)%5
for t in range(25*w):
    if not (t in rhoDict.keys()):
        rhoDict[t] = t

def DictToPerm(permDict, size):
    S = SymmetricGroup(size)
    p = S('()')
    while permDict:
        current = permDict.keys()[0]
        next = permDict.pop(current)
        if (next != current):
            while permDict.has_key(next):
                p = p * S('(' + str(current + 1) + ',' + str(next + 1) + ')')
                next = permDict.pop(next)
    return p

rho = DictToPerm(rhoDict, 25*w)

# Construct pi as a dictionary
piDict = dict()
for x in range(5):
    for y in range(5):
        for z in range(w):
            piDict[FlattenKeccak(x,y,z,w)] = FlattenKeccak((x+3*y)%5, x, z, w)

pi = DictToPerm(piDict, 25*w)


# To speed compiling (which may or may not work)
# this prints a huge array, so Q# can iterate CNOTs over the array,
# rather than having several thousand CNOT statement
def UpperTriangularToArray(U, bufname="state", tabs=0, spaces=4, use_apply_each=True):
    tab = (" " * spaces) if spaces > 0 else "\t"
    code = tab + "let upperMatrix = [\n"
    for row in range(U.dimensions()[0]):
        code += tab + " "*spaces + "[ "
        anyDataFlag = False
        for col in range(row + 1, U.dimensions()[1]):
            if U[row][col] == 1:
                anyDataFlag = True
                code += "%d," % (col)
        code = code[:-1]
        if not anyDataFlag:
            code += "-1"
        code += "],\n"
    code = code[:-2]
    code += tab + "];"
    return code


def LowerTriangularToArray(L, bufname="state", tabs=0, spaces=4, use_apply_each=True):
    tab = (" " * spaces) if spaces > 0 else "\t"
    code = tab + "let lowerMatrix = [\n"
    for row in range(L.dimensions()[0]):
        code += tab + " "*spaces + "[ "
        anyDataFlag = False
        for col in range(row):
            if L[row][col] == 1:
                anyDataFlag = True
                code += "%d," % (col)
        code = code[:-1]
        if not anyDataFlag:
            code += "-1"
        code += "],\n"
    code = code[:-2]
    code += tab + "];"
    return code

P, L, U = theta.LU()
# Theta is followed by rho and pi, which are permutations
P = P * rho * pi
print ('------ pi o rho o theta -----')
filename = 'PiRhoThetaRaw'
pirhotheta = open(filename, 'w')
pirhotheta.write(UpperTriangularToArray(U, "states", 2, 4, false) + "\n" + 
     LowerTriangularToArray(L, "states", 2, 4, false) + "\n")
# Actual Q# code
tab = "    "
pirhotheta.write(tab*4 + "for (idx in 0.." + str(25*w  - 1) + "){\n" + 
                tab*5 + "if (upperMatrix[idx][0] >= 0){\n" +
                tab*6 + "for (idy in 0..Length(upperMatrix[idx]) - 1){\n" + 
                tab*7 + "CNOT(states[upperMatrix[idx][idy]], states[idx]);\n" + 
                tab*6 + "}\n" + 
                tab*5 + "}\n" + 
                tab*4 + "}\n" + 
                tab*4 + "for (idx in " +str(25*w - 1) + "..-1..0){\n" + 
                tab*5 + "if (lowerMatrix[idx][0] >= 0){\n" + 
                tab*6 + "for (idy in 0..Length(lowerMatrix[idx]) - 1){\n" + 
                tab*7 + "CNOT(states[lowerMatrix[idx][idy]], states[idx]);\n" + 
                tab*6 + "}\n" + 
                tab*5 + "}\n" + 
                tab*4 + "}\n")

pirhotheta.write(PermutationToSwap(MatrixToPermutation(P), "states", 2, 4))




pirhotheta.close()
print("  (written to file:" + filename + ")")



# Prints an array to represent the inverse of chi as an S-box
print ('\n\n------ chi (backward) -----')
chiDict = dict()
xArray = [0]*5
for x in range(32):
    for i in range(5):
        xArray[i] = (x >> i) & 1
    sxArray = [0]*5
    for i in range(5):
        sxArray[i] = (xArray[i] + (((xArray[(i+1)%5]+1)%2) * xArray[(i+2)%5]))%2
    sx = 0
    for i in range(5):
        sx += (2**i)*sxArray[i]
    chiDict[sx] = x

backward = ""
for x in range(32):
    backward += str(chiDict[x]) + ", "
print(backward[0:-2])
