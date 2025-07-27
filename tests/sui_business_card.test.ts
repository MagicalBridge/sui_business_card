import { Transaction } from '@mysten/sui/transactions';
import { SuiTestClient } from './utils/sui-client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';

describe('SUI Business Card Smart Contract Tests', () => {
  let suiClient: SuiTestClient;
  let packageId: string;
  let anotherClient: SuiTestClient;

  beforeAll(async () => {
    // 初始化测试客户端
    suiClient = new SuiTestClient();
    
    // 创建另一个用户的客户端用于权限测试
    const anotherKeypair = new Ed25519Keypair();
    anotherClient = new SuiTestClient();
    // 设置不同的密钥对
    Object.defineProperty(anotherClient, 'keypair', { value: anotherKeypair, writable: true });
    
    // 检查包ID是否已设置
    packageId = suiClient.getPackageId();
    if (packageId === '0x0') {
      console.log('需要先发布合约。请运行: npm run deploy:devnet');
      console.log('然后在.env文件中设置PACKAGE_ID');
      return;
    }
    
    anotherClient.setPackageId(packageId);
    
    console.log('测试地址:', suiClient.getAddress());
    console.log('另一个测试地址:', anotherClient.getAddress());
    console.log('包ID:', packageId);
    
    // 检查余额
    const balance = await suiClient.getBalance();
    console.log('当前余额:', balance.toString(), 'MIST');
    
    if (balance < BigInt(100000000)) { // 0.1 SUI
      console.warn('余额可能不足，建议至少有0.1 SUI用于测试');
    }
  });

  describe('正常功能测试', () => {
    test('应该能够成功创建新的喜好信息', async () => {
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(42), // 喜欢的数字
          txb.pure.string('蓝色'), // 喜欢的颜色
          txb.pure.vector('string', ['读书', '游泳', '编程']) // 爱好列表
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
      
      // 获取创建的对象ID
      const createdObjects = result.objectChanges?.filter((change: any) => change.type === 'created');
      expect(createdObjects).toHaveLength(1);
      const favoritesObjectId = createdObjects[0].objectId;
      
      console.log('创建的 Favorites 对象 ID:', favoritesObjectId);
    });





    test('应该能够删除喜好信息', async () => {
      // 为这个测试创建一个新的对象
      const createTxb = new Transaction();
      
      createTxb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          createTxb.pure.u64(123),
          createTxb.pure.string('测试颜色'),
          createTxb.pure.vector('string', ['测试爱好'])
        ],
      });

      const createResult = await suiClient.executeTransaction(createTxb);
      const createdObjects = createResult.objectChanges?.filter((change: any) => change.type === 'created');
      const favoritesObjectId = createdObjects[0].objectId;
      
      // 现在删除这个对象
      const deleteTxb = new Transaction();
      
      deleteTxb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'delete_favorites',
        arguments: [deleteTxb.object(favoritesObjectId)],
      });

      const deleteResult = await suiClient.executeTransaction(deleteTxb);
      expect(deleteResult.effects?.status?.status).toBe('success');
      
      // 验证对象已被删除 - 在 Sui 中对象被删除后查询会抛出错误
      try {
        const objectData = await suiClient.getObject(favoritesObjectId);
        if (objectData.error) {
          // 对象不存在，这是期望的结果
          expect(objectData.error.code).toBe('notExists');
        } else {
          fail('对象应该已经被删除');
        }
      } catch (error) {
        // 预期的错误，对象不存在
      }
    });
  });

  describe('边界条件测试', () => {
    test('应该能够处理最大长度的颜色 (50字符)', async () => {
      const maxLengthColor = 'a'.repeat(50);
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string(maxLengthColor),
          txb.pure.vector('string', ['测试'])
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('应该拒绝超过最大长度的颜色 (51字符)', async () => {
      const tooLongColor = 'a'.repeat(51);
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string(tooLongColor),
          txb.pure.vector('string', ['测试'])
        ],
      });

      try {
        await suiClient.executeTransaction(txb);
        fail('应该抛出颜色过长的错误');
      } catch (error: any) {
        // Move abort 代码 1 对应 EColorTooLong
        expect(error.message).toContain('MoveAbort');
        expect(error.message).toContain('}, 1)');
      }
    });

    test('应该能够处理最大数量的爱好 (5个)', async () => {
      const maxHobbies = ['爱好1', '爱好2', '爱好3', '爱好4', '爱好5'];
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string('颜色'),
          txb.pure.vector('string', maxHobbies)
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('应该拒绝超过最大数量的爱好 (6个)', async () => {
      const tooManyHobbies = ['爱好1', '爱好2', '爱好3', '爱好4', '爱好5', '爱好6'];
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string('颜色'),
          txb.pure.vector('string', tooManyHobbies)
        ],
      });

      try {
        await suiClient.executeTransaction(txb);
        fail('应该抛出爱好数量过多的错误');
      } catch (error: any) {
        // Move abort 代码 2 对应 ETooManyHobbies
        expect(error.message).toContain('MoveAbort');
        expect(error.message).toContain('}, 2)');
      }
    });

    test('应该能够处理最大长度的单个爱好 (50字符)', async () => {
      const maxLengthHobby = 'h'.repeat(50);
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string('颜色'),
          txb.pure.vector('string', [maxLengthHobby])
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('应该拒绝超过最大长度的单个爱好 (51字符)', async () => {
      const tooLongHobby = 'h'.repeat(51);
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(1),
          txb.pure.string('颜色'),
          txb.pure.vector('string', [tooLongHobby])
        ],
      });

      try {
        await suiClient.executeTransaction(txb);
        fail('应该抛出爱好过长的错误');
      } catch (error: any) {
        // Move abort 代码 3 对应 EHobbyTooLong  
        expect(error.message).toContain('MoveAbort');
        expect(error.message).toContain('}, 3)');
      }
    });

    test('应该能够处理空的爱好列表', async () => {
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(99),
          txb.pure.string('绿色'),
          txb.pure.vector('string', []) // 空的爱好列表
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('应该能够处理空的颜色字符串', async () => {
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(0),
          txb.pure.string(''), // 空颜色
          txb.pure.vector('string', ['测试爱好'])
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });
  });

  describe('权限测试', () => {
    let userFavoritesId: string;

    beforeAll(async () => {
      // 创建一个 Favorites 对象供权限测试使用
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(123),
          txb.pure.string('紫色'),
          txb.pure.vector('string', ['权限测试'])
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      const createdObjects = result.objectChanges?.filter((change: any) => change.type === 'created');
      userFavoritesId = createdObjects[0].objectId;
    });

    test('拥有者应该能够更新自己的喜好信息', async () => {
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'update_favorites',
        arguments: [
          txb.object(userFavoritesId),
          txb.pure.u64(456),
          txb.pure.string('黄色'),
          txb.pure.vector('string', ['权限测试更新'])
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('非拥有者应该无法更新他人的喜好信息', async () => {
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'update_favorites',
        arguments: [
          txb.object(userFavoritesId),
          txb.pure.u64(789),
          txb.pure.string('黑色'),
          txb.pure.vector('string', ['非法更新'])
        ],
      });

      try {
        await anotherClient.executeTransaction(txb);
        fail('非拥有者不应该能够更新他人的喜好信息');
      } catch (error: any) {
        // Sui 在对象级别检查权限，会产生 IncorrectUserSignature 错误
        expect(error.message).toContain('IncorrectUserSignature');
      }
    });
  });

  describe('数据完整性测试', () => {
    test('应该正确存储和检索各种数据类型', async () => {
      const testNumber = 999999;
      const testColor = '彩虹色🌈';
      const testHobbies = ['编程💻', '阅读📚', '旅行🌍', '美食🍜'];
      
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(testNumber),
          txb.pure.string(testColor),
          txb.pure.vector('string', testHobbies)
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
      
      const createdObjects = result.objectChanges?.filter((change: any) => change.type === 'created');
      const objectId = createdObjects[0].objectId;
      
      // 验证数据完整性
      const objectData = await suiClient.getObject(objectId);
      const fields = objectData.data?.content?.fields;
      
      expect(fields.number).toBe(testNumber.toString());
      expect(fields.color).toBe(testColor);
      expect(fields.hobbies).toEqual(testHobbies);
      expect(fields.owner).toBe(suiClient.getAddress());
    });

    test('应该能够正确处理 Unicode 字符', async () => {
      const unicodeColor = '紅色🔴';
      const unicodeHobbies = ['学习中文📚', 'プログラミング💻', '한국어 공부📖'];
      
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(777),
          txb.pure.string(unicodeColor),
          txb.pure.vector('string', unicodeHobbies)
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
      
      const createdObjects = result.objectChanges?.filter((change: any) => change.type === 'created');
      const objectId = createdObjects[0].objectId;
      
      // 验证 Unicode 数据
      const objectData = await suiClient.getObject(objectId);
      const fields = objectData.data?.content?.fields;
      
      expect(fields.color).toBe(unicodeColor);
      expect(fields.hobbies).toEqual(unicodeHobbies);
    });
  });

  describe('边界值组合测试', () => {
    test('应该能够处理所有字段都是最大值的情况', async () => {
      const maxNumber = Number.MAX_SAFE_INTEGER;
      const maxColor = 'C'.repeat(50);
      const maxHobbies = Array.from({length: 5}, (_, i) => 'H'.repeat(50));
      
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(maxNumber),
          txb.pure.string(maxColor),
          txb.pure.vector('string', maxHobbies)
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });

    test('应该能够处理所有字段都是最小值的情况', async () => {
      const minNumber = 0;
      const minColor = '';
      const minHobbies: string[] = [];
      
      const txb = new Transaction();
      
      txb.moveCall({
        package: packageId,
        module: 'sui_business_card',
        function: 'set_favorites',
        arguments: [
          txb.pure.u64(minNumber),
          txb.pure.string(minColor),
          txb.pure.vector('string', minHobbies)
        ],
      });

      const result = await suiClient.executeTransaction(txb);
      expect(result.effects?.status?.status).toBe('success');
    });
  });
}); 