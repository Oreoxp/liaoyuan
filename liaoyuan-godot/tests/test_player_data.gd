# res://tests/test_player_data.gd
# 每一个测试脚本都必须继承自 gut's test.gd
extends "res://addons/gut/test.gd"

# 变量声明区
var player_data_instance

# gut's setup 函数，在每个测试用例运行前调用
func before_each():
	# 因为PlayerData是单例，我们直接引用它
	# 在测试前，调用reset确保每次都是从一个干净的状态开始
	PlayerData.reset()
	player_data_instance = PlayerData
	
	# 你可以在这里设置"断言"的期望
	gut.p("测试 PlayerData 开始", 2)

# gut's teardown 函数，在每个测试用例运行后调用
func after_each():
	gut.p("测试 PlayerData 结束", 2)

## --- 测试用例开始 --- ##
# 每个测试函数都必须以 test_ 开头

func test_initial_values():
	assert_eq(player_data_instance.level, 1, "初始等级应为1")
	assert_eq(player_data_instance.current_exp, 0.0, "初始经验应为0")
	
func test_add_experience_no_levelup():
	player_data_instance.add_experience(50)
	assert_eq(player_data_instance.current_exp, 50.0, "增加50经验后，当前经验应为50")
	assert_eq(player_data_instance.level, 1, "增加50经验后，等级不应变化")
	
func test_exact_levelup():
	player_data_instance.add_experience(100) # 1级升2级正好需要100
	assert_eq(player_data_instance.level, 2, "获得100经验后，应升到2级")
	assert_eq(player_data_instance.current_exp, 0.0, "正好升级后，当前经验应归0")
	
func test_overflow_experience_single_levelup():
	player_data_instance.add_experience(150) # 超过升级所需的100
	assert_eq(player_data_instance.level, 2, "获得150经验后，应升到2级")
	assert_almost_eq(player_data_instance.current_exp, 50.0, 0.01, "溢出的50经验应被计入下一级")
	
func test_multi_levelup():
	# 1级(0/100) -> 2级(0/200) -> 3级...
	player_data_instance.add_experience(350) # 100(升2级) + 200(升3级) = 300
	assert_eq(player_data_instance.level, 3, "获得350经验后，应连升两级到3级")
	assert_almost_eq(player_data_instance.current_exp, 50.0, 0.01, "溢出的50经验应被计入3级")
