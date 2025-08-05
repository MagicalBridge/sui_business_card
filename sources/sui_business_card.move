/// 用户业务名片合约 - 存储用户的喜好信息
module sui_business_card::sui_business_card {
    use sui::object::{new, delete, uid_to_address};
    use sui::transfer::{transfer, share_object};
    use sui::tx_context::{sender, epoch_timestamp_ms};
    use sui::package::{Self, UpgradeCap};
    use sui::event;
    use std::string::{utf8, length, String};

    // 错误码定义
    const EColorTooLong: u64 = 1;
    const ETooManyHobbies: u64 = 2;
    const EHobbyTooLong: u64 = 3;
    const EInvalidOwner: u64 = 4;
    const ENotAdmin: u64 = 5;

    // 常量定义
    const MAX_COLOR_LENGTH: u64 = 50;
    const MAX_HOBBIES_COUNT: u64 = 5;
    const MAX_HOBBY_LENGTH: u64 = 50;
    
    // 版本常量
    const CURRENT_VERSION: u64 = 2;

    // =============== 事件定义 ===============
    
    /// 喜好信息创建事件
    public struct FavoritesCreated has copy, drop {
        favorites_id: address,
        owner: address,
        number: u64,
        color: std::string::String,
        hobbies_count: u64,
    }

    /// 喜好信息更新事件
    public struct FavoritesUpdated has copy, drop {
        favorites_id: address,
        owner: address,
        old_number: u64,
        new_number: u64,
        old_color: std::string::String,
        new_color: std::string::String,
    }

    /// 喜好信息删除事件
    public struct FavoritesDeleted has copy, drop {
        favorites_id: address,
        owner: address,
    }

    /// 管理员权限转移事件
    public struct AdminTransferred has copy, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }

    /// 合约升级事件
    public struct ContractUpgraded has copy, drop {
        old_version: u64,
        new_version: u64,
        admin: address,
        timestamp: u64,
    }

    // =============== 结构定义 ===============

    /// 管理员权限结构
    public struct AdminCap has key {
        id: sui::object::UID,
    }

    /// 合约版本信息
    public struct ContractInfo has key {
        id: sui::object::UID,
        version: u64,
        admin: address,
    }

    /// 用户喜好数据结构
    public struct Favorites has key, store {
        id: sui::object::UID,
        owner: address,          // 拥有者地址
        number: u64,             // 喜欢的数字
        color: std::string::String,           // 喜欢的颜色
        hobbies: vector<std::string::String>, // 爱好列表
    }

    /// 包初始化函数 - 在包发布时自动调用
    fun init(ctx: &mut sui::tx_context::TxContext) {
        // 创建管理员权限对象
        let admin_cap = AdminCap {
            id: new(ctx)
        };
        
        // 创建合约信息对象
        let contract_info = ContractInfo {
            id: new(ctx),
            version: CURRENT_VERSION,
            admin: sender(ctx),
        };
        
        // 将管理员权限转移给部署者
        transfer(admin_cap, sender(ctx));
        
        // 将合约信息设为共享对象，所有人都可以查看
        share_object(contract_info);
    }

    /// 升级包的入口函数
    public entry fun upgrade_contract(
        upgrade_cap: &mut UpgradeCap,
        _admin_cap: &AdminCap,
        contract_info: &mut ContractInfo,
        ctx: &sui::tx_context::TxContext
    ) {
        // 验证管理员权限
        assert!(contract_info.admin == sender(ctx), ENotAdmin);
        
        // 记录旧版本号
        let old_version = contract_info.version;
        
        // 这里可以添加升级前的准备工作
        // 比如数据迁移、状态清理等
        
        // 更新版本号
        contract_info.version = contract_info.version + 1;
        
        // 发射合约升级事件
        event::emit(ContractUpgraded {
            old_version,
            new_version: contract_info.version,
            admin: sender(ctx),
            timestamp: epoch_timestamp_ms(ctx),
        });
    }

    /// 获取合约版本
    public fun get_contract_version(contract_info: &ContractInfo): u64 {
        contract_info.version
    }

    /// 转移管理员权限
    public entry fun transfer_admin(
        admin_cap: AdminCap,
        contract_info: &mut ContractInfo,
        new_admin: address,
        ctx: &sui::tx_context::TxContext
    ) {
        // 验证当前管理员
        assert!(contract_info.admin == sender(ctx), ENotAdmin);
        
        let old_admin = contract_info.admin;
        
        // 更新管理员地址
        contract_info.admin = new_admin;
        
        // 发射管理员转移事件
        event::emit(AdminTransferred {
            old_admin,
            new_admin,
            timestamp: epoch_timestamp_ms(ctx),
        });
        
        // 转移权限对象
        transfer(admin_cap, new_admin);
    }

    /// 设置用户喜好信息
    /// 参数:
    /// - number: 用户喜欢的数字
    /// - color: 用户喜欢的颜色
    /// - hobbies: 用户的爱好列表
    public entry fun set_favorites(
        number: u64,
        color: vector<u8>,
        hobbies: vector<vector<u8>>,
        ctx: &mut sui::tx_context::TxContext
    ) {
        let sender = sender(ctx);
        
        // 转换颜色为String并验证长度
        let color_string = utf8(color);
        assert!(length(&color_string) <= MAX_COLOR_LENGTH, EColorTooLong);
        
        // 验证爱好数量
        assert!(vector::length(&hobbies) <= MAX_HOBBIES_COUNT, ETooManyHobbies);
        
        // 转换爱好列表为String向量并验证每个爱好的长度
        let mut hobbies_strings = vector::empty<std::string::String>();
        let mut i = 0;
        let hobbies_len = vector::length(&hobbies);
        
        while (i < hobbies_len) {
            let hobby_bytes = vector::borrow(&hobbies, i);
            let hobby_string = utf8(*hobby_bytes);
            assert!(length(&hobby_string) <= MAX_HOBBY_LENGTH, EHobbyTooLong);
            vector::push_back(&mut hobbies_strings, hobby_string);
            i = i + 1;
        };

        // 创建喜好对象
        let favorites = Favorites {
            id: new(ctx),
            owner: sender,
            number,
            color: color_string,
            hobbies: hobbies_strings,
        };

        // 发射喜好创建事件
        event::emit(FavoritesCreated {
            favorites_id: uid_to_address(&favorites.id),
            owner: sender,
            number,
            color: color_string,
            hobbies_count: vector::length(&hobbies_strings),
        });

        // 将对象转移给调用者
        transfer(favorites, sender);
    }

    /// 更新现有的喜好信息
    /// 参数:
    /// - favorites: 可变引用的喜好对象
    /// - number: 新的喜欢数字
    /// - color: 新的喜欢颜色
    /// - hobbies: 新的爱好列表
    public entry fun update_favorites(
        favorites: &mut Favorites,
        number: u64,
        color: vector<u8>,
        hobbies: vector<vector<u8>>,
        ctx: &sui::tx_context::TxContext
    ) {
        // 验证调用者是否为拥有者
        assert!(favorites.owner == sender(ctx), EInvalidOwner);
        
        // 记录旧值用于事件
        let old_number = favorites.number;
        let old_color = favorites.color;
        
        // 转换颜色为String并验证长度
        let color_string = utf8(color);
        assert!(length(&color_string) <= MAX_COLOR_LENGTH, EColorTooLong);
        
        // 验证爱好数量
        assert!(vector::length(&hobbies) <= MAX_HOBBIES_COUNT, ETooManyHobbies);
        
        // 转换爱好列表为String向量并验证每个爱好的长度
        let mut hobbies_strings = vector::empty<std::string::String>();
        let mut i = 0;
        let hobbies_len = vector::length(&hobbies);
        
        while (i < hobbies_len) {
            let hobby_bytes = vector::borrow(&hobbies, i);
            let hobby_string = utf8(*hobby_bytes);
            assert!(length(&hobby_string) <= MAX_HOBBY_LENGTH, EHobbyTooLong);
            vector::push_back(&mut hobbies_strings, hobby_string);
            i = i + 1;
        };

        // 更新字段
        favorites.number = number;
        favorites.color = color_string;
        favorites.hobbies = hobbies_strings;
        
        // 发射更新事件
        event::emit(FavoritesUpdated {
            favorites_id: uid_to_address(&favorites.id),
            owner: favorites.owner,
            old_number,
            new_number: number,
            old_color,
            new_color: color_string,
        });
    }

    /// 获取用户喜好的数字
    public fun get_number(favorites: &Favorites): u64 {
        return favorites.number
    }

    /// 获取用户喜好的颜色
    public fun get_color(favorites: &Favorites): std::string::String {
        return favorites.color
    }

    /// 获取用户的爱好列表
    public fun get_hobbies(favorites: &Favorites): vector<std::string::String> {
        return favorites.hobbies
    }

    /// 获取拥有者地址
    public fun get_owner(favorites: &Favorites): address {
        return favorites.owner
    }

    /// 获取所有喜好信息（用于查询）
    public fun get_all_favorites(favorites: &Favorites): (u64, std::string::String, vector<std::string::String>) {
        (favorites.number, favorites.color, favorites.hobbies)
    }

    /// 删除喜好对象
    public entry fun delete_favorites(favorites: Favorites, _ctx: &sui::tx_context::TxContext) {
        // 发射删除事件（在删除前发射，因为删除后对象就不存在了）
        event::emit(FavoritesDeleted {
            favorites_id: uid_to_address(&favorites.id),
            owner: favorites.owner,
        });
        
        let Favorites { id, owner: _, number: _, color: _, hobbies: _ } = favorites;
        delete(id);
    }

    // 测试用的初始化函数
    #[test_only]
    public fun init_for_testing(_ctx: &mut sui::tx_context::TxContext) {
        // 测试时可以创建一些初始数据
    }
}


