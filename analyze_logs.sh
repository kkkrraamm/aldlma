#!/bin/bash

# 🔍 محلل اللوقز - يحلل لوقز Flutter الموجودة
# by Abdulkarim ✨

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}      🔍 محلل اللوقز - Dalma App${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo ""

# قراءة اللوقز من Terminal الحالي
echo -e "${YELLOW}📋 قم بلصق اللوقز التي تريد تحليلها ثم اضغط Ctrl+D:${NC}"
echo ""

INPUT=""
while IFS= read -r line; do
    INPUT+="$line"$'\n'
done

if [ -z "$INPUT" ]; then
    echo -e "${RED}❌ لم يتم إدخال أي لوقز للتحليل${NC}"
    exit 1
fi

# عدادات
TYPE_ERRORS=0
NULL_ERRORS=0
STATE_ERRORS=0
NETWORK_ERRORS=0
DATABASE_ERRORS=0
RENDER_ERRORS=0
CAST_ERRORS=0
INDEX_ERRORS=0

# مصفوفات التفاصيل
declare -a ERROR_LINES=()
declare -a CRITICAL_ERRORS=()

echo ""
echo -e "${CYAN}🔎 جارٍ تحليل اللوقز...${NC}"
echo ""

# تحليل كل سطر
while IFS= read -r line; do
    if echo "$line" | grep -iq "type.*string.*is not a subtype.*type.*int.*index"; then
        ((TYPE_ERRORS++))
        ((INDEX_ERRORS++))
        CRITICAL_ERRORS+=("$line")
        echo -e "${RED}❌ [CRITICAL] Type/Index Error: $line${NC}"
    
    elif echo "$line" | grep -iq "type.*is not a subtype\|type.*mismatch"; then
        ((TYPE_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${RED}❌ [TYPE] $line${NC}"
    
    elif echo "$line" | grep -iq "\.cast<.*>"; then
        ((CAST_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${YELLOW}⚠️  [CAST] استخدام cast<>() قد يسبب مشاكل: $line${NC}"
    
    elif echo "$line" | grep -iq "null.*exception\|null check"; then
        ((NULL_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${RED}❌ [NULL] $line${NC}"
    
    elif echo "$line" | grep -iq "setState.*after dispose\|bad state"; then
        ((STATE_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${RED}❌ [STATE] $line${NC}"
    
    elif echo "$line" | grep -iq "404\|500\|403\|connection.*refused\|timeout"; then
        ((NETWORK_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${YELLOW}⚠️  [NETWORK] $line${NC}"
    
    elif echo "$line" | grep -iq "sql.*error\|database.*error\|relation.*does not exist"; then
        ((DATABASE_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${RED}❌ [DATABASE] $line${NC}"
    
    elif echo "$line" | grep -iq "overflow.*pixels\|renderbox"; then
        ((RENDER_ERRORS++))
        ERROR_LINES+=("$line")
        echo -e "${YELLOW}⚠️  [RENDER] $line${NC}"
    fi
done <<< "$INPUT"

# التقرير النهائي
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}           📊 نتائج التحليل${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo ""

TOTAL=$((TYPE_ERRORS + NULL_ERRORS + STATE_ERRORS + NETWORK_ERRORS + DATABASE_ERRORS + RENDER_ERRORS))

echo -e "${BLUE}📈 إجمالي الأخطاء المكتشفة: ${RED}$TOTAL${NC}"
echo ""

if [ $TOTAL -eq 0 ]; then
    echo -e "${GREEN}✅ لم يتم اكتشاف أخطاء واضحة في اللوقز!${NC}"
    echo -e "${GREEN}   التطبيق يبدو أنه يعمل بشكل طبيعي 🎉${NC}"
else
    echo -e "${CYAN}┌─ التفصيل:${NC}"
    [ $TYPE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Type Errors: $TYPE_ERRORS ❌${NC}"
    [ $INDEX_ERRORS -gt 0 ] && echo -e "${CYAN}│  └─${RED} Index Type Errors: $INDEX_ERRORS (حرج!) 🔴${NC}"
    [ $CAST_ERRORS -gt 0 ] && echo -e "${CYAN}│  └─${YELLOW} Cast Operations: $CAST_ERRORS (مشكوك فيها) ⚠️${NC}"
    [ $NULL_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Null Errors: $NULL_ERRORS ❌${NC}"
    [ $STATE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} State Errors: $STATE_ERRORS ❌${NC}"
    [ $NETWORK_ERRORS -gt 0 ] && echo -e "${CYAN}├─${YELLOW} Network Issues: $NETWORK_ERRORS ⚠️${NC}"
    [ $DATABASE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Database Errors: $DATABASE_ERRORS ❌${NC}"
    [ $RENDER_ERRORS -gt 0 ] && echo -e "${CYAN}└─${YELLOW} Render Issues: $RENDER_ERRORS ⚠️${NC}"
fi

echo ""

# الأخطاء الحرجة
if [ ${#CRITICAL_ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}🔴 أخطاء حرجة تحتاج إلى إصلاح فوري:${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for err in "${CRITICAL_ERRORS[@]}"; do
        echo -e "${YELLOW}   • $err${NC}"
    done
    echo ""
    echo -e "${GREEN}💡 الحل:${NC}"
    echo -e "   ${CYAN}المشكلة: type 'String' is not a subtype of type 'int' of 'index'${NC}"
    echo -e "   ${GREEN}السبب: استخدام cast<String>() بدلاً من map().toList()${NC}"
    echo ""
    echo -e "   ${YELLOW}التصحيح المطلوب:${NC}"
    echo -e "   ${RED}❌ قبل: list.cast<String>()${NC}"
    echo -e "   ${GREEN}✅ بعد: list.map((e) => e.toString()).toList()${NC}"
    echo ""
    echo -e "   ${CYAN}الملفات المحتملة:${NC}"
    echo -e "   - lib/trends_page.dart"
    echo -e "   - lib/media_posts_page.dart"
    echo -e "   - أي مكان يستخدم cast<String>() على Lists"
    echo ""
fi

# اقتراحات إضافية
if [ $TYPE_ERRORS -gt 0 ] || [ $CAST_ERRORS -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  توصيات عامة لأخطاء Type:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   1️⃣  تجنب استخدام .cast<T>() قدر الإمكان"
    echo -e "   2️⃣  استخدم .map((e) => e.toString()).toList() للتحويل الآمن"
    echo -e "   3️⃣  تحقق من الأنواع قبل التحويل باستخدام 'is'"
    echo -e "   4️⃣  استخدم int.tryParse() بدلاً من التحويل المباشر"
    echo -e "   5️⃣  راجع جميع الـ Lists القادمة من Backend/API"
    echo ""
fi

if [ $NULL_ERRORS -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  توصيات لأخطاء Null:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   • استخدم value ?? defaultValue"
    echo -e "   • استخدم value?.property"
    echo -e "   • تحقق من null قبل الاستخدام: if (value != null)"
    echo ""
fi

echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}تم الانتهاء من التحليل ✅${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo ""

