import os
from sys import exit
from numpy import isnan, isinf, nanmean, nanstd
from pandas import DataFrame as DF, read_csv, read_excel
os.chdir(os.path.abspath(os.path.dirname(__file__)))#解析进入程序所在目录
EXIT_SUCCESS = 0
EXIT_FAILURE = 1
EOF = (-1)


def readCsvExcel(filepath) -> DF:
	if filepath.lower().endswith(".csv"):
		return read_csv(filepath)
	else:
		return read_excel(filepath)

def getArrayDict(folder = ".", resultName = "result.csv") -> dict:
	arrayDict = {} # round -> dict
	for item in os.listdir(folder):
		if os.path.isdir(item) and item.lower().startswith("round_"):
			try:
				pf = readCsvExcel(os.path.join(os.path.join(folder, item), resultName))
				arrayDict[int(item[6:])] = pf
			except Exception as e:
				print(e)
	return arrayDict

def getSchemeIDList(arrayDict) -> list:
	schemeIDList = []
	for pf in list(arrayDict.values()):
		for id in pf["schemeID"]:
			if id not in schemeIDList:
				schemeIDList.append(id)
	return schemeIDList

def getFunctionIDList(arrayDict) -> list:
	functionIDList = []
	for pf in list(arrayDict.values()):
		for id in pf["functionID"]:
			if id not in functionIDList:
				functionIDList.append(id)
	return functionIDList

def removeNanInf(lists) -> list:
	for i in range(len(lists) - 1, -1, -1):
		if isnan(lists[i]) or isinf(lists[i]):
			del lists[i]
	return lists

def getTotalInfo(arrayDict, schemeIDList) -> dict:
	scheme_best_fitness = {schemeID:[] for schemeID in schemeIDList}
	scheme_iteration = {schemeID:[] for schemeID in schemeIDList}
	scheme_iteration_time = {schemeID:[] for schemeID in schemeIDList}
	scheme_info = {}
	for schemeID in schemeIDList:
		for pf in list(arrayDict.values()):
			scheme_best_fitness[schemeID] += removeNanInf(pf[pf["schemeID"] == schemeID]["best_fitness"].values.tolist())
			scheme_iteration[schemeID] += removeNanInf(pf[pf["schemeID"] == schemeID]["iteration"].values.tolist())
			scheme_iteration_time[schemeID] += removeNanInf(pf[pf["schemeID"] == schemeID]["iteration_time"].values.tolist())
		scheme_info[schemeID] = {						\
			"best_fitness":{						\
				"mean":nanmean(scheme_best_fitness[schemeID]), 		\
				"std":nanstd(scheme_best_fitness[schemeID]), 		\
				"var":nanstd(scheme_best_fitness[schemeID]) ** 2		\
			}, 							\
			"iteration":{						\
				"mean":nanmean(scheme_iteration[schemeID]), 		\
				"std":nanstd(scheme_iteration[schemeID]), 		\
				"var":nanstd(scheme_iteration[schemeID]) ** 2		\
			}, 							\
			"iteration_time":{						\
				"mean":nanmean(scheme_iteration_time[schemeID]), 	\
				"std":nanstd(scheme_iteration_time[schemeID]), 		\
				"var":nanstd(scheme_iteration_time[schemeID]) ** 2		\
			}							\
		}
	return scheme_info

def getSchemeToFunctionInfo(arrayDict, schemeIDList, functionIDList) -> dict:
	scheme_best_fitness = {schemeID:{functionID:[] for functionID in functionIDList} for schemeID in schemeIDList}
	scheme_iteration = {schemeID:{functionID:[] for functionID in functionIDList} for schemeID in schemeIDList}
	scheme_iteration_time = {schemeID:{functionID:[] for functionID in functionIDList} for schemeID in schemeIDList}
	scheme_to_function_info = {}
	for schemeID in schemeIDList:
		for functionID in functionIDList:
			for pf in list(arrayDict.values()):
				scheme_best_fitness[schemeID][functionID] += removeNanInf(pf[(pf["schemeID"] == schemeID) & (pf["functionID"] == functionID)]["best_fitness"].values.tolist())
				scheme_iteration[schemeID][functionID] += removeNanInf(pf[(pf["schemeID"] == schemeID) & (pf["functionID"] == functionID)]["iteration"].values.tolist())
				scheme_iteration_time[schemeID][functionID] += removeNanInf(pf[(pf["schemeID"] == schemeID) & (pf["functionID"] == functionID)]["iteration_time"].values.tolist())
			scheme_to_function_info.setdefault(schemeID, {})
			scheme_to_function_info[schemeID][functionID] = {						\
				"best_fitness":(								\
					{								\
						"mean":nanmean(scheme_best_fitness[schemeID][functionID]), 	\
						"std":nanstd(scheme_best_fitness[schemeID][functionID]), 		\
						"var":nanstd(scheme_best_fitness[schemeID][functionID]) ** 2		\
					} if scheme_best_fitness[schemeID][functionID] else {			\
						"mean":float("nan"), 						\
						"std":float("nan"), 						\
						"var":float("nan")						\
					}								\
				), 									\
				"iteration":(								\
					{								\
						"mean":nanmean(scheme_iteration[schemeID][functionID]), 		\
						"std":nanstd(scheme_iteration[schemeID][functionID]), 		\
						"var":nanstd(scheme_iteration[schemeID][functionID]) ** 2		\
					} if scheme_iteration[schemeID][functionID] else {				\
						"mean":float("nan"), 						\
						"std":float("nan"), 						\
						"var":float("nan")						\
					}								\
				), 									\
				"iteration_time":(								\
					{								\
						"mean":nanmean(scheme_iteration_time[schemeID][functionID]), 	\
						"std":nanstd(scheme_iteration_time[schemeID][functionID]), 		\
						"var":nanstd(scheme_iteration_time[schemeID][functionID]) ** 2	\
					}  if scheme_iteration_time[schemeID][functionID] else {			\
						"mean":float("nan"), 						\
						"std":float("nan"), 						\
						"var":float("nan")						\
					}								\
				)									\
			}
	return scheme_to_function_info

def dump_r(fp, current_pointer, line, layer = 0) -> None:
	if type(current_pointer) == dict:
		for key in sorted(list(current_pointer.keys())):
			line[layer] = key
			dump_r(fp, current_pointer[key], line, layer + 1)
	elif type(current_pointer) in (tuple, list, set):
		for ele in current_pointer:
			dump_r(fp, ele, line, layer + 1)
	else: # element
		line[layer] = current_pointer
		line_to_write = [""] * (max(list(line.keys())) + 1)
		for index in list(line.keys()):
			line_to_write[index] = str(line[index])
		fp.write(",".join(line_to_write))
		fp.write("\n")
		line.clear()

def dump(dicts, filepath, encoding = "utf-8") -> bool:
	line = {}
	try:
		with open(filepath, "w", encoding = encoding) as f:
			dump_r(f, dicts, line)
		return True
	except Exception as e:
		print(e)
		return False

def main() -> int:
	arrayDict = getArrayDict() # round -> dict
	schemeIDList = getSchemeIDList(arrayDict)
	print("schemeIDList:", schemeIDList)
	functionIDList = getFunctionIDList(arrayDict)
	print("functionIDList:", functionIDList)
	scheme_info = getTotalInfo(arrayDict, schemeIDList)
	print("scheme_info:", scheme_info)
	dump(scheme_info, "scheme_info.csv")
	scheme_to_function_info = getSchemeToFunctionInfo(arrayDict, schemeIDList, functionIDList)
	print("scheme_to_function_info:", scheme_to_function_info)
	dump(scheme_to_function_info, "scheme_to_function_info.csv")
	return EXIT_SUCCESS



if __name__ == "__main__":
	exit(main())
