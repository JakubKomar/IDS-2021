# IDS-2021
--notes--
v er nutno upravit vztahy requirement-invoice (v databázi nelze vytvořit rovnou s tímto vztahem)->(opravit na 0-n,0-1) navíc to dává větší smysl takhle
--notes end--

--poslední část--
popis:
Vytvoření + naplnění tavbulek, poté zadefinuje či vytvoří pokročilá omezení či objekty databáze. Dále skript bude obsahovat ukázkové příkazy manipulace dat a dotazy demonstrující použití výše zmiňovaných omezení a objektů tohoto skriptu (např. pro demonstraci použití indexů zavolá nejprve skript EXPLAIN PLAN na dotaz bez indexu, poté vytvoří index, a nakonec zavolá EXPLAIN PLAN na dotaz s indexem; pro demostranci databázového triggeru se provede manipulace s daty, která vyvolá daný trigger; atp.).

to do:
2 trigry-       1. na generování pk (bylo by vhodné to provést u faktur)
                2. jaký chceme
2 procedury-    v jedné musí být kurzor, 
                ošetření výjimek, 
                použití proměnné s datovým typem odkazujícím se na řádek či typ sloupce tabulky (table_name.column_name%TYPE nebo table_name%ROWTYPE)
1 EXPLAIN PLAN- pro výpis plánu provedení databazového dotazu se spojením alespoň dvou tabulek, agregační funkcí a klauzulí GROUP BY
                -v dokumentaci musí být srozumitelně popsáno, jak proběhne dle toho výpisu plánu provedení dotazu, vč. objasnění použitých prostředků pro jeho urychlení (např. použití indexu, druhu spojení, atp.),               
                -dále musí být navrnut způsob, jak konkrétně by bylo možné dotaz dále urychlit (např. zavedením nového indexu), navržený způsob proveden (např. vytvořen index), zopakován EXPLAIN PLAN a jeho výsledek porovnán s výsledkem před provedením navrženého způsobu urychlení,
-definice přístupových práv k databázovým objektům pro druhého člena týmu,
-vytvořen alespoň jeden materializovaný pohled patřící druhému členu týmu a používající tabulky definované prvním členem týmu (nutno mít již definována přístupová práva), vč. SQL příkazů/dotazů ukazujících, jak materializovaný pohled funguje,
