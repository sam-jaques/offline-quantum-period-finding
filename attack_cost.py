# Unless specified otherwise, all variables represent the logarithm of the relevant number

import math
import copy
import csv

# Global constants for the cost metric
ALL_GATES = 0
T_GATES = 1

G_COST = 0
DW_COST  = 1

COST_METRIC = ALL_GATES
COST_MODEL = G_COST

Q_SHARP_SUBFOLDER = "LowT"

# Miscellaneous constants
LOG_ADD_THRESHOLD = 10

# Global constants for costs of fundamental gates
if COST_METRIC == T_GATES:
	TOFFOLI_GATES = math.log(4, 2.0)
	TOFFOLI_DEPTH = 0
	CSWAP_GATES = TOFFOLI_GATES
	CSWAP_DEPTH = TOFFOLI_DEPTH
	AND_GATES = math.log(4, 2.0)
	AND_DEPTH = 0
	UNAND_GATES = -LOG_ADD_THRESHOLD # 0 t-gates
	UNAND_DEPTH = -LOG_ADD_THRESHOLD # 0 t-gates
	BOTH_AND_GATES = AND_GATES
	BOTH_AND_DEPTH = AND_DEPTH
	CNOT_GATE = -float('inf')
	CNOT_DEPTH = -float('inf')
	CLIFFORD_GATE = -float('inf')
	CLIFFORD_DEPTH = -float('inf')
else:
	TOFFOLI_GATES = math.log(25, 2.0)
	TOFFOLI_DEPTH = math.log(7, 2.0)
	CSWAP_GATES = math.log(27, 2.0)
	CSWAP_DEPTH = math.log(9, 2.0)
	AND_GATES = math.log(15, 2.0)
	AND_DEPTH = math.log(8, 2.0)
	UNAND_GATES = math.log(5, 2.0)
	UNAND_DEPTH = math.log(3, 2.0)
	BOTH_AND_GATES = math.log(20, 2.0)
	BOTH_AND_DEPTH = math.log(11, 2.0)
	CNOT_DEPTH = 0
	CNOT_GATE = 0
	CLIFFORD_GATE = 0
	CLIFFORD_DEPTH = 0



# Other global constants
EVEN_MANSOUR = 0
FX = 1


#########################################################
# Functions to perform arithmetic on data where x represents 2^x

def log2(x):
	if x <= 0:
		return -float('inf')
	else:
		return math.log(x, 2.0)

def log_multiply(x, y):
	return x+y

# log(x+y) = log(x) + log(1+y/x)
def log_add(x, y):
	z = max(x,y)
	w = min(x,y)
	if w == -float('inf'):
		return z
	if z - w > LOG_ADD_THRESHOLD:
		return z
	return z + log2( 1 + 2 ** (w - z))

def log_subtract(x, y):
	if x < y:
		print("Warning: negative number from subtraction")
	if x <= y:
		return - float('inf')
	if x - y > LOG_ADD_THRESHOLD:
		return x
	return x + log2(1 - 2 ** (y - x))
#########################################################
#     Class and functions to deal with cost tuples
#########################################################
# Width: the inputs and outputs
# Ancilla: Temporary qubits
class QuantumCost:
	def __init__(self, depth, width, gates, ancilla = -float('inf')):
		self.depth = depth
		self.width = width
		self.gates = gates
		self.ancilla = ancilla


	def __repr__(self):
		return "\n  Gates:\t" + str(self.gates) + "\n  Depth:\t" + str(self.depth) + "\n  Qubits\n    Width:\t" + str(self.width) + "\n    Ancilla:\t" + str(self.ancilla) + "\n    Total:\t" + str(log_add(self.width, self.ancilla)) + "\n"

def max_cost():
	return QuantumCost(float('inf'), float('inf'), float('inf'), float('inf'))

def empty_cost():
	return QuantumCost(-float('inf'), -float('inf'), -float('inf'),-float('inf'))


#Cost of two sequential operations
def sequential_cost(cost1, cost2):	
		return QuantumCost(
			log_add(cost1.depth, cost2.depth),
			max(cost1.width, cost2.width),
			log_add(cost1.gates, cost2.gates),
			max(cost1.ancilla,cost2.ancilla),
		)

def parallel_cost(cost1, cost2):
	return QuantumCost(
		max(cost1.depth, cost2.depth),
		log_add(cost1.width, cost2.width),
		log_add(cost1.gates, cost2.gates),
		log_add(cost1.ancilla, cost2.ancilla),
	)

#Assume inputs become outputs
def sequential_repeat(cost, iterations):
	return QuantumCost(
		iterations + cost.depth, 
		cost.width,
		iterations + cost.gates,
		cost.ancilla
	)

def parallel_repeat(cost, iterations):
	return QuantumCost(
		cost.depth,
		iterations + cost.width,
		iterations + cost.gates,
		iterations + cost.ancilla,
	)

def get_cost(cost):
	if COST_MODEL == G_COST:
		return cost.gates
	else:
		return max(cost.gates, cost.depth + log_add(cost.width, cost.ancilla))

def cost_compare(cost1, cost2):
	if get_cost(cost1) < get_cost(cost2):
		return True
	else:
		return False


# Obtains exact costs from a file output by Q#
# Inputs:
#    - filename: the .csv file of costs
#    - first_arg and second_arg: for parameterized costs,
#        (e.g., rank has parameters of height and width)
#        these are the numerical values of the paramters
#    - strict: governs whether it accepts any match in the first_arg, 
#        or whether it needs both args to match
def get_qsharp_cost(filename, first_arg, second_arg, input_size, strict = False):
	csv.register_dialect('cost_csv_dialect', skipinitialspace = True)
	with open(filename, newline="\n") as csvfile:
		csvCosts = csv.DictReader(csvfile, dialect='cost_csv_dialect')
		cost = empty_cost()
		for row in csvCosts:
			if (row['first arg'] == first_arg):
				cost.width = input_size
				cost.ancilla = log2(int(row['Full width']) - 2**input_size)
				if COST_METRIC == ALL_GATES:
					cost.depth = log2(int(row['Full depth']))
					cost.gates = CNOT_GATE + log2(int(row['CNOT count']))
					cost.gates = log_add(cost.gates, CLIFFORD_GATE + log2(int(row['1-qubit Clifford count']) + int(row['M count'])))
					cost.gates = log_add(cost.gates, log2(int(row['T count'])))
				else:
					cost.depth = log2(int(row['T depth']))
					cost.gates = log2(int(row['T count']))
				# Just take the cost if its the right guess size
				if second_arg and (row['second arg'] == second_arg):
					return cost
	if strict:
		return None
	else:
		return cost
#########################################################


class DepthError(Exception):
	pass


############################# QRAM FUNCTION #################################
# Finds the cost to look up words of size word_size in a table of size table_size,
# subject to a depth constraint
# First checks a simple look-up (Babbush et al.)
# If this is not shallow enough, tries the Berry et al. approach
# If this is still too wide, returns a wide look-up
def get_lookup_cost(table_size, EXP_word_size):
	return QuantumCost(
		table_size + log_add(BOTH_AND_DEPTH, 1 + log2(log2(EXP_word_size) - 1) + CNOT_DEPTH), # depth
		log_add(log2(table_size), log2(EXP_word_size)),
		table_size + log_add(BOTH_AND_GATES, log2(1.5) + log2(EXP_word_size) + CNOT_GATE),
		log_add(log2(table_size), log2(EXP_word_size))
	)




############################# RANK FUNCTION #################################
# Cost of computing whether an n x m binary matrix has full rank
# Depth is empirically derived from a linear estimation from Q#
# Width does not match results because the width includes the output qubit
def rank_cost(EXP_n, EXP_m):
	if EXP_m > EXP_n:
		return rank_cost(EXP_m, EXP_n)
	# If there are results from a full Q# output, use those
	filename = "Simon/RankCalculation/" + Q_SHARP_SUBFOLDER + "/Rank"
	if COST_METRIC == ALL_GATES:
		filename += "-all-gates"
	filename += ".csv"
	cost = get_qsharp_cost(filename, str(EXP_m), str(EXP_n), log2(EXP_n * EXP_m), True)
	if cost: return cost
	gates = log2(14 * EXP_n * EXP_m * (EXP_m-1) + 60) # t-gates
	gates = log_add(gates, CNOT_GATE + log2(23.7 * EXP_n * EXP_m * (EXP_m - 1) - 1435))
	gates = log_add(gates, CLIFFORD_GATE + log2(4*EXP_n*EXP_m*(EXP_m-1) + 230))
	if COST_METRIC == T_GATES:
		depth = log2(2.06*(EXP_m+EXP_n) * (log2(EXP_m)+log2(EXP_n)+1) + 363)
	else:
		depth = log2(6.61*(EXP_m+EXP_n) * (log2(EXP_m)+log2(EXP_n)+1) + 1086)
	width = log2(EXP_n*EXP_m)
	ancilla = log2(EXP_m*(3*EXP_m-1)/2 + EXP_n)
	return QuantumCost(depth, width, gates, ancilla)



############################# SIMON FUNCTIONS #################################
# Cost of attacking an Even-Mansour cipher, for a fixed u
def single_offline_simon_attack_cost(depth_limit, cipher, EXP_u, success_prob = -2):

	# Find linear system size necessary
	# Based on Theorm 14 of Bonnetain 2020
	EXP_lin_system_size = cipher.EXP_block_size + cipher.EXP_key_size - success_prob + 4
	# Based on Theorem 8 of Bonnetain 2020
	EXP_word_size = math.ceil(log2(4*math.e*EXP_lin_system_size))
	
	cipher_cost = get_cipher_cost(cipher, EXP_u, EXP_word_size)

	if success_prob >= 0:
		raise Exception('Success probability must be a negative exponent')
	if cipher_cost.depth > depth_limit:
		raise Exception('Cipher is too large to fit in depth limit')
	if cipher.EXP_block_size < EXP_u:
		raise Exception('Invalid u value (larger than block size)')

	# Total number of iterations of the Grover search
	if cipher.cipher_type == EVEN_MANSOUR:
		total_grover_iterates = (cipher.EXP_block_size - EXP_u)/2 + log2(math.pi/2)
		if cipher.EXP_key_size > 0:
			print('Warning: given non-zero key size for Even-Mansour type cipher')
	elif cipher.cipher_type == FX:
		total_grover_iterates = (cipher.EXP_block_size - EXP_u + cipher.EXP_key_size)/2 + log2(math.pi/2)
	else:
		raise Exception("Invalid cipher type")
	
	# Everything should be in log base 2
	lin_system_size = log2(EXP_lin_system_size)
	# Create the superposition of the g-database
	setup_cost=parallel_repeat(get_lookup_cost(EXP_u, EXP_word_size), lin_system_size)


	# print ("Setup: ", setup_cost)
	# apply the cipher 
	# running in parallel
	key_cost = dummy_key_cost(cipher)
	oracle_cost = parallel_cost(key_cost, parallel_repeat(cipher_cost, lin_system_size))

	# solve the linear system
	linear_cost = rank_cost(EXP_lin_system_size, EXP_u)
	oracle_cost = sequential_cost(oracle_cost, linear_cost)

	# At this point it applies the Hadamard gates and flips the phase, but this is
	# invisible relative to the other costs
	
	# print ("Oracle: ", oracle_cost)

	# How many grover iterations can we fit in the depth limit?
	grover_depth = log_subtract(depth_limit, setup_cost.depth) - oracle_cost.depth
	grover_depth = min(grover_depth, total_grover_iterates)
	# How much does a single grover iteration search?
	single_grover_cost = sequential_repeat(oracle_cost, grover_depth)
	# print("Single grover cost: ", single_grover_cost)
	# Total cost (including parallelization)
	total_grover_cost = parallel_repeat(single_grover_cost, 2*(total_grover_iterates - grover_depth))


	total_cost = sequential_cost(setup_cost, total_grover_cost)

	# setup + grover search
	return {'setup': setup_cost, 'rank': linear_cost, 'total': total_cost, 'oracle_reps' : EXP_lin_system_size}

# Finds the best u by brute force
# Returns a dictionary of the u and the various associated costs
#
# Inputs
# depth_limit:
#    Limit (in log2) of the depth available to the attacker
# cipher:
#    A Cipher object to estimate
# block_size:
#    The message block size of the cipher (and hence also the length of "key 1")
# cipher_type:
#    Equal to either EVAN_MANSOUR or FX, dictating which type of attack
# key_size:
#    For FX-style ciphers, this is the size of the key for the permutation
# success_prob:
#    A negative number indicating the lg of the necessary probability of failure for the full algorithm
# query_limit:
#    Any protocol limit on the number of queries
def best_offline_simon_attack_cost(depth_limit, cipher, success_prob = -2, query_limit = float('inf')):
	query_limit = min(query_limit, cipher.EXP_block_size)
	best_cost = {'total': max_cost()}
	for EXP_u in range(query_limit + 1):
		# print("============u: " + str(u) + "====================")
		cost = single_offline_simon_attack_cost(depth_limit, cipher, EXP_u, success_prob)
		if get_cost(cost['total']) < get_cost(best_cost['total']):
			best_cost = cost
			best_cost['u'] = EXP_u
	return best_cost



############################# CIPHER ORACLE FUNCTIONS #################################
# Looks up the cost of a cipher from CSV files
def get_cipher_cost(cipher, guess_size = 0, word_size = 0):
	filename = "Simon/CipherCosts/" + Q_SHARP_SUBFOLDER + "/" + cipher.name
	if COST_METRIC == ALL_GATES:
		filename += "-all-gates"
	filename += ".csv"
	cost = get_qsharp_cost(filename, str(cipher.parameter), str(guess_size), log2(guess_size + word_size), False)
	cost.ancilla = log_subtract(cost.ancilla, log2(cipher.EXP_key_size))
	return cost
	
# Cost with no gates/depth, but a width
# Used to ensure qubits are allocated for keys
def dummy_key_cost(cipher):
	c = empty_cost()
	c.width = log2(cipher.EXP_key_size)
	return c

# Data structure to hold data on different block ciphers
class Cipher:
	def __init__(self, name, EXP_block_size, EXP_key_size, EXP_pre_key_size, cipher_type, query_limit = None,parameter = None):
		self.name = name
		self.EXP_block_size = EXP_block_size
		self.EXP_key_size = EXP_key_size
		self.cipher_type = cipher_type
		self.EXP_pre_key_size = EXP_pre_key_size
		if query_limit:
			self.query_limit = query_limit
		else:
			self.query_limit = 1000
		if parameter:
			self.parameter = parameter
		else:
			self.parameter = EXP_block_size

ciphers = [
	Cipher('Chaskey', 128, 0, 128, EVEN_MANSOUR, 48,8),
	Cipher('Chaskey', 128, 0, 128, EVEN_MANSOUR, 48,12),
	Cipher('Prince', 64, 64, 64, FX, 48),
	Cipher('Elephant', 160, 0, 128, EVEN_MANSOUR,47),
	Cipher('Elephant', 176, 0, 128, EVEN_MANSOUR,47),
	Cipher('Elephant', 200, 0, 128, EVEN_MANSOUR,69)
]



def tex_format_result(cipher, result, t_result):
	# assuming a table of the form:
	# name & bitlength & queries & gates & t-gates & depth & t-depth & qubits \\
	row = cipher.name
	row += " & " + str(cipher.EXP_block_size)
	row += " & " + str(result['u'])
	row += " & " + str(round(result['total'].gates, 1))
	row += " & " + str(round(t_result['total'].gates, 1))
	row += " & " + str(round(result['total'].depth, 1))
	row += " & " + str(round(t_result['total'].depth, 1))
	row += " & " + str(round(log_add(result['total'].width, result['total'].ancilla), 1)) + "\\\\\n"
	return row


########################################################################################
#                           Main Computation 
########################################################################################
for query_limit in [True, False]:
	for cipher in ciphers:
		limit = 1000
		if query_limit : limit = cipher.query_limit
		print("=====Cipher: " + cipher.name + "-" + str(cipher.parameter) + " , query limit " + str(limit) + "==========")
		COST_METRIC = ALL_GATES
		# Finds the optimal number of queries by brute force, based on total gate cost
		# answer is a dictionary of the costs and the query number ('u')
		answer = best_offline_simon_attack_cost(1000, cipher, query_limit = limit)
		# Adds data on the cipher itself
		answer['cipher'] = get_cipher_cost(cipher, answer['u'], 11)
		# For the optimal number of queries (answer['u']), finds the T cost of that attack
		COST_METRIC = T_GATES
		t_answer = single_offline_simon_attack_cost(1000, cipher, answer['u'])
		print(tex_format_result(cipher, answer, t_answer))
		print(" Linear system size: " + str(answer['oracle_reps']))





########################################################################################
#                                 Grover search
########################################################################################
print("========================================================")
print("=========================GROVER=========================")
print("========================================================")


def get_grover_cost(cipher, prob_threshold = 20):
	filename = "Simon/GroverCosts/" + Q_SHARP_SUBFOLDER + "/" + cipher.name
	if COST_METRIC == ALL_GATES:
		filename += "-all-gates"
	filename += ".csv"
	n_queries = math.ceil((cipher.EXP_key_size + cipher.EXP_pre_key_size + 20)/cipher.EXP_block_size)
	cost = empty_cost()
	for n in range(n_queries):
		num_repetitions = (n_queries - n)*log2(math.pi/4.0) + max((cipher.EXP_key_size + cipher.EXP_pre_key_size - n*cipher.EXP_block_size)/2,0)
		# We repeat sequentially a single cost
		cipher_cost = sequential_repeat(get_qsharp_cost(filename, str(cipher.parameter), str(1), -float('inf')), n+1)
		cost = sequential_cost(cost, sequential_repeat(cipher_cost, num_repetitions))
	return cost

for cipher in ciphers:
	print("=====Cipher: " + cipher.name + "-" + str(cipher.parameter) + " , query limit " + str(limit) + "==========")
	answer = dict()
	COST_METRIC = ALL_GATES
	answer['total'] = get_grover_cost(cipher)
	answer['u'] = 0
	t_answer = dict()
	COST_METRIC = T_GATES
	t_answer['total'] = get_grover_cost(cipher)
	print(tex_format_result(cipher, answer, t_answer))