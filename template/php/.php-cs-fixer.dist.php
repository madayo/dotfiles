<?php

// "version": "v3.6.0" で動作確認済み
// 細かいルールは https://mlocati.github.io/php-cs-fixer-configurator/ で確認

require_once __DIR__.'/vendor/autoload.php';

$finder = PhpCsFixer\Finder::create()
    ->in([__DIR__]);
    // Laravel 用
    // ->in([
    //     __DIR__ . '/app',
    //     __DIR__ . '/config',
    //     __DIR__ . '/database',
    //     __DIR__ . '/routes',
    //     __DIR__ . '/tests',
    // ]);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true, // ルールセット @PSR12 を使用する
        // https://qiita.com/ucan-lab/items/7d4180462347a42009d5 を参考にした。様子見て調整
        'blank_line_after_opening_tag' => false,
        'linebreak_after_opening_tag' => false,
        'declare_strict_types' => true,
        'phpdoc_types_order' => [
            'null_adjustment' => 'always_last',
            'sort_algorithm' => 'none',
        ],
        'no_superfluous_phpdoc_tags' => false,
        'global_namespace_import' => [
            'import_classes' => true,
            'import_constants' => true,
            'import_functions' => true,
        ],
        'php_unit_test_case_static_method_calls' => [
            'call_type' => 'this'
        ],
        'phpdoc_align' => [
            'align' => 'left',
        ],
        'not_operator_with_successor_space' => true,
        'blank_line_after_namespace' => true,
        'final_class' => true,
        'date_time_immutable' => true,
        'declare_parentheses' => true,
        'final_public_method_for_abstract_class' => true,
        'mb_str_functions' => true,
        'simplified_if_return' => true,
        'simplified_null_return' => true,
    ])
    ->setLineEnding("\n")
    ->setFinder($finder);
