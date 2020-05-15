local config = {
    redis = {
        host = '127.0.0.1',
        port = 6379,
        pass = '',
        timeout = 200, -- watch out this value
        database = 0
    },

    db = {
        -- host = "120.78.95.34",
        -- port = 3306,
        -- user = "gugule",
        -- password = "%)BMlEj634*I2&Uj",
        -- database = "gugule"
        host = "127.0.0.1",
        port = 3306,
        user = "root",
        password = "123456",
        database = "gugule"
    }
}
return config
