#[test_only]
module sui_business_card::sui_business_card_tests {
    use sui_business_card::sui_business_card::{Self, Favorites};
    use sui::test_scenario::{Self, next_tx, ctx};
    use std::string;

    // 测试账户地址
    const OWNER: address = @0x1;
    const OTHER_USER: address = @0x2;

    #[test]
    fun test_set_favorites_success() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // 创建测试数据
        let number = 42;
        let color = b"blue";
        let hobbies = vector[b"reading", b"coding", b"swimming"];
        
        // 测试设置喜好
        next_tx(&mut scenario, OWNER);
        {
            sui_business_card::set_favorites(
                number,
                color,
                hobbies,
                ctx(&mut scenario)
            );
        };
        
        // 验证对象是否创建成功
        next_tx(&mut scenario, OWNER);
        {
            let favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            
            // 验证数据
            assert!(sui_business_card::get_number(&favorites) == 42, 0);
            assert!(sui_business_card::get_color(&favorites) == string::utf8(b"blue"), 1);
            assert!(sui_business_card::get_owner(&favorites) == OWNER, 2);
            
            let stored_hobbies = sui_business_card::get_hobbies(&favorites);
            assert!(vector::length(&stored_hobbies) == 3, 3);
            assert!(*vector::borrow(&stored_hobbies, 0) == string::utf8(b"reading"), 4);
            assert!(*vector::borrow(&stored_hobbies, 1) == string::utf8(b"coding"), 5);
            assert!(*vector::borrow(&stored_hobbies, 2) == string::utf8(b"swimming"), 6);
            
            test_scenario::return_to_sender(&scenario, favorites);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_favorites_success() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // 先创建喜好对象
        next_tx(&mut scenario, OWNER);
        {
            sui_business_card::set_favorites(
                42,
                b"blue",
                vector[b"reading"],
                ctx(&mut scenario)
            );
        };
        
        // 更新喜好
        next_tx(&mut scenario, OWNER);
        {
            let mut favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            
            sui_business_card::update_favorites(
                &mut favorites,
                99,
                b"red",
                vector[b"gaming", b"music"],
                ctx(&mut scenario)
            );
            
            // 验证更新后的数据
            assert!(sui_business_card::get_number(&favorites) == 99, 0);
            assert!(sui_business_card::get_color(&favorites) == string::utf8(b"red"), 1);
            
            let updated_hobbies = sui_business_card::get_hobbies(&favorites);
            assert!(vector::length(&updated_hobbies) == 2, 2);
            assert!(*vector::borrow(&updated_hobbies, 0) == string::utf8(b"gaming"), 3);
            assert!(*vector::borrow(&updated_hobbies, 1) == string::utf8(b"music"), 4);
            
            test_scenario::return_to_sender(&scenario, favorites);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_all_favorites() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            sui_business_card::set_favorites(
                123,
                b"green",
                vector[b"dancing", b"singing"],
                ctx(&mut scenario)
            );
        };
        
        next_tx(&mut scenario, OWNER);
        {
            let favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            
            let (number, color, hobbies) = sui_business_card::get_all_favorites(&favorites);
            
            assert!(number == 123, 0);
            assert!(color == string::utf8(b"green"), 1);
            assert!(vector::length(&hobbies) == 2, 2);
            assert!(*vector::borrow(&hobbies, 0) == string::utf8(b"dancing"), 3);
            assert!(*vector::borrow(&hobbies, 1) == string::utf8(b"singing"), 4);
            
            test_scenario::return_to_sender(&scenario, favorites);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_delete_favorites() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            sui_business_card::set_favorites(
                42,
                b"blue",
                vector[b"reading"],
                ctx(&mut scenario)
            );
        };
        
        next_tx(&mut scenario, OWNER);
        {
            let favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            sui_business_card::delete_favorites(favorites, ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = 1)] // EColorTooLong
    fun test_color_too_long() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            let long_color = b"this_is_a_very_long_color_name_that_exceeds_fifty_characters_limit";
            sui_business_card::set_favorites(
                42,
                long_color,
                vector[b"reading"],
                ctx(&mut scenario)
            );
        };
        
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = 2)] // ETooManyHobbies
    fun test_too_many_hobbies() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            let too_many_hobbies = vector[
                b"hobby1", b"hobby2", b"hobby3", 
                b"hobby4", b"hobby5", b"hobby6"
            ];
            sui_business_card::set_favorites(
                42,
                b"blue",
                too_many_hobbies,
                ctx(&mut scenario)
            );
        };
        
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = 3)] // EHobbyTooLong  
    fun test_hobby_too_long() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            let long_hobby = b"this_is_a_very_long_hobby_name_that_exceeds_the_fifty_character_limit_for_hobbies";
            sui_business_card::set_favorites(
                42,
                b"blue",
                vector[long_hobby],
                ctx(&mut scenario)
            );
        };
        
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = 4)] // EInvalidOwner
    fun test_update_by_non_owner() {
        let mut scenario = test_scenario::begin(OTHER_USER);
        
        // 先让OTHER_USER创建一个对象
        next_tx(&mut scenario, OTHER_USER);
        {
            sui_business_card::set_favorites(
                42,
                b"blue",
                vector[b"reading"],
                ctx(&mut scenario)
            );
        };
        
        // 现在用OWNER作为发送者来尝试更新，但对象的拥有者是OTHER_USER
        next_tx(&mut scenario, OWNER);
        {
            let mut favorites = test_scenario::take_from_address<Favorites>(&scenario, OTHER_USER);
            
            // 这应该失败，因为OWNER不是原始拥有者
            sui_business_card::update_favorites(
                &mut favorites,
                99,
                b"red",
                vector[b"gaming"],
                ctx(&mut scenario)
            );
            
            test_scenario::return_to_address(OTHER_USER, favorites);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_empty_hobbies() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            sui_business_card::set_favorites(
                42,
                b"blue",
                vector[], // 空的爱好列表
                ctx(&mut scenario)
            );
        };
        
        next_tx(&mut scenario, OWNER);
        {
            let favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            
            let hobbies = sui_business_card::get_hobbies(&favorites);
            assert!(vector::length(&hobbies) == 0, 0);
            
            test_scenario::return_to_sender(&scenario, favorites);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_maximum_valid_limits() {
        let mut scenario = test_scenario::begin(OWNER);
        
        next_tx(&mut scenario, OWNER);
        {
            // 测试最大有效限制
            let max_color = b"12345678901234567890123456789012345678901234567890"; // 恰好50字符
            let max_hobbies = vector[
                b"12345678901234567890123456789012345678901234567890", // 50字符
                b"hobby2",
                b"hobby3", 
                b"hobby4",
                b"hobby5"  // 恰好5个爱好
            ];
            
            sui_business_card::set_favorites(
                42,
                max_color,
                max_hobbies,
                ctx(&mut scenario)
            );
        };
        
        next_tx(&mut scenario, OWNER);
        {
            let favorites = test_scenario::take_from_sender<Favorites>(&scenario);
            
            // 验证数据正确存储
            let color = sui_business_card::get_color(&favorites);
            assert!(string::length(&color) == 50, 0);
            
            let hobbies = sui_business_card::get_hobbies(&favorites);
            assert!(vector::length(&hobbies) == 5, 1);
            assert!(string::length(vector::borrow(&hobbies, 0)) == 50, 2);
            
            test_scenario::return_to_sender(&scenario, favorites);
        };
        
        test_scenario::end(scenario);
    }
}
