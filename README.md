## sui cli 常用命令

```bash
# 查看所有环境
sui client envs
╭──────────┬─────────────────────────────────────┬────────╮
│ alias    │ url                                 │ active │
├──────────┼─────────────────────────────────────┼────────┤
│ testnet  │ https://fullnode.testnet.sui.io:443 │        │
│ mainnet  │ https://fullnode.mainnet.sui.io:443 │        │
│ devnet   │ https://fullnode.devnet.sui.io:443  │ *      │
│ localnet │ http://127.0.0.1:9000               │        │
╰──────────┴─────────────────────────────────────┴────────╯

# 当前所在的环境
sui client active-env
devnet

# 查看所有地址
sui client addresses

# 查看当前活跃地址
sui client active-address
0x2b2de21fdb1400064ee37ca9e459c1bac13fc0ee1eebc676fc499e59c7f1559b

# 查看余额
sui client balance
╭────────────────────────────────────────╮
│ Balance of coins owned by this address │
├────────────────────────────────────────┤
│ ╭──────────────────────────────────╮   │
│ │ coin  balance (raw)  balance     │   │
│ ├──────────────────────────────────┤   │
│ │ Sui   39984695440    39.98 SUI   │   │
│ ╰──────────────────────────────────╯   │
╰────────────────────────────────────────╯

# 列出所有密钥信息
sui keytool list

# 导出私钥（使用地址）
sui keytool export --key-identity [你的地址]

# 查看对象
sui client object 0xcbb1fa1e99ba3103cbf23550ac52bf5b622f2aff2f21ee9595177ca625ad626a
```