import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

export class ContractUpgrader {
  private network: string;
  private packageId!: string;
  private upgradeCapId!: string;

  constructor(network?: string) {
    this.network = network || this.getCurrentActiveNetwork();
    this.loadConfiguration();
    console.log(`准备升级${this.network}网络上的合约`);
  }

  private getCurrentActiveNetwork(): string {
    try {
      const envsOutput = execSync('sui client envs', { 
        cwd: process.cwd(), 
        encoding: 'utf8' 
      });

      const lines = envsOutput.split('\n');
      for (const line of lines) {
        if (line.includes('*')) {
          const columns = line.split('│').map(col => col.trim());
          if (columns.length >= 4 && columns[3] === '*') {
            return columns[1];
          }
        }
      }
      
      console.warn('未能检测到当前激活的网络，使用默认的 localnet');
      return 'localnet';
    } catch (error) {
      console.warn('检测网络环境失败，使用默认的 localnet:', error);
      return 'localnet';
    }
  }

  private loadConfiguration(): void {
    const envPath = path.join(process.cwd(), '.env');
    
    if (!fs.existsSync(envPath)) {
      throw new Error('.env 文件不存在，请先部署合约');
    }

    const envContent = fs.readFileSync(envPath, 'utf8');
    
    // 读取包ID
    const packageIdMatch = envContent.match(/PACKAGE_ID=(.+)/);
    if (!packageIdMatch) {
      throw new Error('在.env文件中找不到PACKAGE_ID');
    }
    this.packageId = packageIdMatch[1].trim();

    // 读取升级权限ID
    const upgradeCapMatch = envContent.match(/UPGRADE_CAP_ID=(.+)/);
    if (!upgradeCapMatch) {
      throw new Error('在.env文件中找不到UPGRADE_CAP_ID，可能需要重新部署合约');
    }
    this.upgradeCapId = upgradeCapMatch[1].trim();
  }

  async upgradeContract(): Promise<string> {
    try {
      // 检查当前网络
      const currentNetwork = this.getCurrentActiveNetwork();
      if (currentNetwork !== this.network) {
        console.log(`切换到${this.network}网络...`);
        execSync(`sui client switch --env ${this.network}`, { 
          cwd: process.cwd(), 
          stdio: 'inherit' 
        });
      }

      console.log('当前配置:');
      console.log('- 包ID:', this.packageId);
      console.log('- 升级权限ID:', this.upgradeCapId);
      console.log('- 网络:', this.network);

      // 构建Move项目
      console.log('\n构建更新的Move项目...');
      execSync('sui move build', { cwd: process.cwd(), stdio: 'inherit' });

      // 执行升级
      console.log('\n执行合约升级...');
      const upgradeCommand = `sui client upgrade --package-id ${this.packageId} --upgrade-capability ${this.upgradeCapId} --gas-budget 20000000 --json`;
      
      const result = execSync(upgradeCommand, { 
        cwd: process.cwd(), 
        encoding: 'utf8' 
      });

      const upgradeResult = JSON.parse(result);
      
      if (upgradeResult.effects?.status?.status !== 'success') {
        throw new Error(`合约升级失败: ${upgradeResult.effects?.status?.error}`);
      }

      // 从升级结果中提取新的包ID
      const newPackageId = upgradeResult.objectChanges?.find(
        (change: any) => change.type === 'published'
      )?.packageId;

      if (!newPackageId) {
        throw new Error('无法找到升级后的包ID');
      }

      console.log('\n✅ 合约升级成功！');
      console.log('新包ID:', newPackageId);

      // 更新配置文件
      this.updatePackageId(newPackageId);

      return newPackageId;
    } catch (error) {
      console.error('❌ 升级失败:', error);
      throw error;
    }
  }

  private updatePackageId(newPackageId: string): void {
    const envPath = path.join(process.cwd(), '.env');
    let envContent = fs.readFileSync(envPath, 'utf8');
    
    // 更新包ID
    if (envContent.includes('PACKAGE_ID=')) {
      envContent = envContent.replace(/PACKAGE_ID=.*/, `PACKAGE_ID=${newPackageId}`);
    } else {
      envContent += `\nPACKAGE_ID=${newPackageId}\n`;
    }

    fs.writeFileSync(envPath, envContent);
    console.log('新的包ID已保存到.env文件');
  }

  /**
   * 检查升级权限状态
   */
  async checkUpgradeCapability(): Promise<void> {
    try {
      const command = `sui client object ${this.upgradeCapId} --json`;
      const result = execSync(command, { 
        cwd: process.cwd(), 
        encoding: 'utf8' 
      });

      const objectInfo = JSON.parse(result);
      console.log('\n升级权限状态:');
      console.log('- 对象ID:', this.upgradeCapId);
      console.log('- 拥有者:', objectInfo.data?.owner);
      console.log('- 对象类型:', objectInfo.data?.type);
      
    } catch (error) {
      console.error('检查升级权限失败:', error);
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  const networkArg = process.argv[2];
  const upgrader = new ContractUpgrader(networkArg);
  
  // 检查升级权限状态
  upgrader.checkUpgradeCapability()
    .then(() => upgrader.upgradeContract())
    .then(newPackageId => {
      console.log(`\n🎉 升级完成！`);
      console.log(`📦 新包ID: ${newPackageId}`);
      console.log(`\n现在你可以运行测试验证升级:`);
      console.log(`npm test`);
    })
    .catch(error => {
      console.error('升级过程失败:', error);
      process.exit(1);
    });
} 