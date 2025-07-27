/// 用户业务名片合约 - 存储用户的喜好信息
module sui_business_card::sui_business_card {
    use sui::object::{new, delete};
    use sui::transfer::transfer;
    use sui::tx_context::sender;
    use std::string::{utf8, length};
    use std::vector;

    // 错误码定义
    const EColorTooLong: u64 = 1;
    const ETooManyHobbies: u64 = 2;
    const EHobbyTooLong: u64 = 3;
    const EInvalidOwner: u64 = 4;

    // 常量定义
    const MAX_COLOR_LENGTH: u64 = 50;
    const MAX_HOBBIES_COUNT: u64 = 5;
    const MAX_HOBBY_LENGTH: u64 = 50;

    /// 用户喜好数据结构
    public struct Favorites has key, store {
        id: sui::object::UID,
        owner: address,          // 拥有者地址
        number: u64,             // 喜欢的数字
        color: std::string::String,           // 喜欢的颜色
        hobbies: vector<std::string::String>, // 爱好列表
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
    }

    /// 获取用户喜好的数字
    public fun get_number(favorites: &Favorites): u64 {
        favorites.number
    }

    /// 获取用户喜好的颜色
    public fun get_color(favorites: &Favorites): std::string::String {
        favorites.color
    }

    /// 获取用户的爱好列表
    public fun get_hobbies(favorites: &Favorites): vector<std::string::String> {
        favorites.hobbies
    }

    /// 获取拥有者地址
    public fun get_owner(favorites: &Favorites): address {
        favorites.owner
    }

    /// 获取所有喜好信息（用于查询）
    public fun get_all_favorites(favorites: &Favorites): (u64, std::string::String, vector<std::string::String>) {
        (favorites.number, favorites.color, favorites.hobbies)
    }

    /// 删除喜好对象
    public entry fun delete_favorites(favorites: Favorites, _ctx: &sui::tx_context::TxContext) {
        let Favorites { id, owner: _, number: _, color: _, hobbies: _ } = favorites;
        delete(id);
    }

    // 测试用的初始化函数
    #[test_only]
    public fun init_for_testing(_ctx: &mut sui::tx_context::TxContext) {
        // 测试时可以创建一些初始数据
    }
}


