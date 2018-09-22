#ifndef TLS_DEFINE_H
#define TLS_DEFINE_H

/// 国家类别
enum _TLS_COUNTRY_DEFINE
{
    TLS_COUNTRY_CHINA = 86,           ///中国
    TLS_COUNTRY_TAIWAN = 186,         ///台湾
    TLS_COUNTRY_HONGKANG = 152,       ///香港
    TLS_COUNTRY_USA = 174,            ///美国
};

/// 语言类别
enum _TLS_LANG_DEFINE
{
    TLS_LANG_ENGLISH = 1033,          ///英语
    TLS_LANG_SIMPLIFIED = 2052,       ///简体中文，目前只支持简体中文
    TLS_LANG_TRADITIONAL = 1028,      ///繁体中文
    TLS_LANG_JAPANESE = 1041,         ///日语
    TLS_LANG_FRANCE = 1036,           ///法语
};

#endif