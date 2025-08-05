Sui Business Card Contract Deployment Information

# 历史部署记录

## 第一次部署 (2025-01-04)
Network: devnet
Package ID: 0x6f6b570275ca0ecdbd2513e7c4ca27692becdac8863435414a5a6c3d2a3c2854
Upgrade Cap ID: 0xabfef7e7ab038249629bd2ebfa72423b56cf4a7c85960248090a3852e1f74f29
Admin Cap ID: 0x2a97512b3cf1adc6de758dd00466ce219cd2377a7c09cb35f8d55a586394d939
Contract Info ID: 0xa2e56de1d8c5594b05e1bbe72ead353b58c50389c348a62e249f7126eb10d1cb
Deployer Address: 0x2b2de21fdb1400064ee37ca9e459c1bac13fc0ee1eebc676fc499e59c7f1559b
Transaction Hash: E1Yq2LtdAXKUyNUhSuxH2Hu2vkKAfbsxqWoJnXnJB4rf
Gas Used: 0.020192280 SUI
Status: Successfully deployed to devnet

## 最新部署 (2025-08-05)
Generated on: 2025-08-05 12:39:29
Network: devnet
Package ID: 0x8b64be6c582d328f2b593394b267524b27695f420234f7486079d51f23a6ee1c
Upgrade Cap ID: 0xcbb1fa1e99ba3103cbf23550ac52bf5b622f2aff2f21ee9595177ca625ad626a
Deployer Address: 0x2b2de21fdb1400064ee37ca9e459c1bac13fc0ee1eebc676fc499e59c7f1559b
Balance Before Deploy: 20.00 SUI
Status: Successfully deployed to devnet

# 当前活跃配置 (.env)
SUI_NETWORK=devnet
PACKAGE_ID=0x8b64be6c582d328f2b593394b267524b27695f420234f7486079d51f23a6ee1c
UPGRADE_CAP_ID=0xcbb1fa1e99ba3103cbf23550ac52bf5b622f2aff2f21ee9595177ca625ad626a
TEST_PRIVATE_KEY=[已配置]

# 升级演示记录

## 升级准备工作已完成 ✅
1. **添加事件系统** - 为合约添加了5个重要事件：
   - FavoritesCreated - 喜好信息创建事件
   - FavoritesUpdated - 喜好信息更新事件  
   - FavoritesDeleted - 喜好信息删除事件
   - AdminTransferred - 管理员权限转移事件
   - ContractUpgraded - 合约升级事件

2. **版本号更新** - 从版本1升级到版本2
3. **升级脚本修复** - 修复了升级命令的参数问题
4. **代码编译成功** - 新版本合约编译通过

## 对象信息记录
- **Admin Cap ID**: 0xad1eaa375d8d03797e3882257669dbcb43f852f1f1b04aa2de04d0a2de90f50f
- **Contract Info ID**: 0xd1359f7326d33856a636fa7199055438050d0e98837274f0aa28f16b35678a90
- **Upgrade Cap ID**: 0xcbb1fa1e99ba3103cbf23550ac52bf5b622f2aff2f21ee9595177ca625ad626a

## 升级执行状态
状态: 准备就绪，需要升级Sui客户端
原因: 客户端版本1.53.1与服务器版本1.54.0不匹配
解决方案: 执行 `sui client update` 或重新安装最新版Sui客户端

## 升级命令 (客户端更新后使用)
```bash
sui client upgrade --upgrade-capability 0xcbb1fa1e99ba3103cbf23550ac52bf5b622f2aff2f21ee9595177ca625ad626a --gas-budget 200000000
```

