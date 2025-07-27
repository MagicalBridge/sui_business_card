## 如何导出本地地址的私钥


```bash
# 1. 查看所有地址
sui client addresses

# 2. 列出所有密钥信息
sui keytool list

# 3. 导出私钥（使用地址）
sui keytool export --key-identity [你的地址]
```