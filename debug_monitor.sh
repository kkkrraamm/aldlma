#!/bin/bash

# 🔍 مدقق اللوقز التلقائي لتطبيق Dalma
# يراقب الأخطاء ويحللها تلقائياً
# by Abdulkarim ✨

# الألوان للـ Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# عدادات الأخطاء
TYPE_ERRORS=0
NULL_ERRORS=0
STATE_ERRORS=0
NETWORK_ERRORS=0
DATABASE_ERRORS=0
RENDER_ERRORS=0
OTHER_ERRORS=0

# مصفوفات لتخزين الأخطاء
declare -a TYPE_ERROR_DETAILS=()
declare -a NULL_ERROR_DETAILS=()
declare -a STATE_ERROR_DETAILS=()
declare -a NETWORK_ERROR_DETAILS=()
declare -a DATABASE_ERROR_DETAILS=()
declare -a RENDER_ERROR_DETAILS=()
declare -a OTHER_ERROR_DETAILS=()

echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}      🔍 مدقق اللوقز التلقائي - Dalma App${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⏳ جارٍ مراقبة اللوقز...${NC}"
echo -e "${YELLOW}   اضغط Ctrl+C للإيقاف وعرض التقرير${NC}"
echo ""

# ملف اللوقز المؤقت
LOG_FILE="/tmp/dalma_flutter_logs.txt"
> "$LOG_FILE"

# دالة لتحليل الأخطاء
analyze_error() {
    local line="$1"
    local timestamp=$(date '+%H:%M:%S')
    
    # فحص أخطاء Type
    if echo "$line" | grep -iq "type.*is not a subtype\|type.*mismatch\|cast.*failed"; then
        ((TYPE_ERRORS++))
        TYPE_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${RED}❌ [TYPE ERROR] $line${NC}"
    
    # فحص أخطاء Null
    elif echo "$line" | grep -iq "null.*exception\|null check operator\|null is not a subtype"; then
        ((NULL_ERRORS++))
        NULL_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${RED}❌ [NULL ERROR] $line${NC}"
    
    # فحص أخطاء State
    elif echo "$line" | grep -iq "setState.*called after dispose\|bad state\|concurrent modification"; then
        ((STATE_ERRORS++))
        STATE_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${RED}❌ [STATE ERROR] $line${NC}"
    
    # فحص أخطاء Network
    elif echo "$line" | grep -iq "connection.*refused\|timeout\|socket.*exception\|failed to fetch\|404\|500\|403"; then
        ((NETWORK_ERRORS++))
        NETWORK_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${YELLOW}⚠️  [NETWORK ERROR] $line${NC}"
    
    # فحص أخطاء Database
    elif echo "$line" | grep -iq "sql.*error\|database.*error\|query.*failed\|relation.*does not exist"; then
        ((DATABASE_ERRORS++))
        DATABASE_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${RED}❌ [DATABASE ERROR] $line${NC}"
    
    # فحص أخطاء Render/Overflow
    elif echo "$line" | grep -iq "overflow.*pixels\|renderbox.*not laid out\|constraints.*not satisfied"; then
        ((RENDER_ERRORS++))
        RENDER_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${YELLOW}⚠️  [RENDER ERROR] $line${NC}"
    
    # أخطاء أخرى
    elif echo "$line" | grep -iq "exception\|error\|failed\|❌"; then
        ((OTHER_ERRORS++))
        OTHER_ERROR_DETAILS+=("[$timestamp] $line")
        echo -e "${YELLOW}⚠️  [OTHER ERROR] $line${NC}"
    fi
}

# دالة لطباعة التقرير النهائي
print_report() {
    echo ""
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           📊 تقرير تحليل الأخطاء${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    echo ""
    
    # إجمالي الأخطاء
    TOTAL=$((TYPE_ERRORS + NULL_ERRORS + STATE_ERRORS + NETWORK_ERRORS + DATABASE_ERRORS + RENDER_ERRORS + OTHER_ERRORS))
    
    echo -e "${BLUE}📈 إجمالي الأخطاء: ${RED}$TOTAL${NC}"
    echo ""
    
    # تفصيل الأخطاء
    echo -e "${CYAN}┌─ تفصيل الأخطاء حسب النوع:${NC}"
    echo -e "${CYAN}│${NC}"
    [ $TYPE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Type Errors:${NC} $TYPE_ERRORS ❌"
    [ $NULL_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Null Errors:${NC} $NULL_ERRORS ❌"
    [ $STATE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} State Errors:${NC} $STATE_ERRORS ❌"
    [ $NETWORK_ERRORS -gt 0 ] && echo -e "${CYAN}├─${YELLOW} Network Errors:${NC} $NETWORK_ERRORS ⚠️"
    [ $DATABASE_ERRORS -gt 0 ] && echo -e "${CYAN}├─${RED} Database Errors:${NC} $DATABASE_ERRORS ❌"
    [ $RENDER_ERRORS -gt 0 ] && echo -e "${CYAN}├─${YELLOW} Render Errors:${NC} $RENDER_ERRORS ⚠️"
    [ $OTHER_ERRORS -gt 0 ] && echo -e "${CYAN}└─${YELLOW} Other Errors:${NC} $OTHER_ERRORS ⚠️"
    echo ""
    
    # تفاصيل أخطاء Type (الأهم)
    if [ $TYPE_ERRORS -gt 0 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🔴 Type Errors (أخطاء الأنواع - الأكثر أهمية):${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for detail in "${TYPE_ERROR_DETAILS[@]}"; do
            echo -e "${YELLOW}   • $detail${NC}"
        done
        echo ""
        echo -e "${GREEN}💡 الحل المقترح:${NC}"
        echo -e "   - تحقق من استخدام cast<T>() واستبدله بـ map().toList()"
        echo -e "   - تأكد من تحويل الأنواع بشكل صريح (int.tryParse, toString())"
        echo -e "   - استخدم type checking قبل التحويل (is String, is int)"
        echo ""
    fi
    
    # تفاصيل أخطاء Null
    if [ $NULL_ERRORS -gt 0 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🔴 Null Errors (أخطاء القيم الفارغة):${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for detail in "${NULL_ERROR_DETAILS[@]}"; do
            echo -e "${YELLOW}   • $detail${NC}"
        done
        echo ""
        echo -e "${GREEN}💡 الحل المقترح:${NC}"
        echo -e "   - استخدم null safety operators (??, ?.)"
        echo -e "   - تحقق من القيم قبل الاستخدام (if (value != null))"
        echo -e "   - استخدم القيم الافتراضية (value ?? defaultValue)"
        echo ""
    fi
    
    # تفاصيل أخطاء State
    if [ $STATE_ERRORS -gt 0 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🔴 State Errors (أخطاء الحالة):${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for detail in "${STATE_ERROR_DETAILS[@]}"; do
            echo -e "${YELLOW}   • $detail${NC}"
        done
        echo ""
        echo -e "${GREEN}💡 الحل المقترح:${NC}"
        echo -e "   - تحقق من mounted قبل استدعاء setState()"
        echo -e "   - استخدم if (mounted) setState(() {...})"
        echo -e "   - تأكد من dispose() في الوقت المناسب"
        echo ""
    fi
    
    # تفاصيل أخطاء Network
    if [ $NETWORK_ERRORS -gt 0 ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  Network Errors (أخطاء الشبكة):${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for detail in "${NETWORK_ERROR_DETAILS[@]}"; do
            echo -e "${CYAN}   • $detail${NC}"
        done
        echo ""
        echo -e "${GREEN}💡 الحل المقترح:${NC}"
        echo -e "   - تحقق من اتصال الإنترنت"
        echo -e "   - تأكد من أن الـ Backend يعمل على Render"
        echo -e "   - راجع الـ API endpoints والـ headers"
        echo ""
    fi
    
    # تفاصيل أخطاء Database
    if [ $DATABASE_ERRORS -gt 0 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🔴 Database Errors (أخطاء قاعدة البيانات):${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for detail in "${DATABASE_ERROR_DETAILS[@]}"; do
            echo -e "${YELLOW}   • $detail${NC}"
        done
        echo ""
        echo -e "${GREEN}💡 الحل المقترح:${NC}"
        echo -e "   - تحقق من schema قاعدة البيانات"
        echo -e "   - راجع الـ SQL queries في Backend"
        echo -e "   - تأكد من وجود الجداول والأعمدة المطلوبة"
        echo ""
    fi
    
    # الخلاصة
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    if [ $TOTAL -eq 0 ]; then
        echo -e "${GREEN}✅ لم يتم اكتشاف أي أخطاء! التطبيق يعمل بشكل مثالي 🎉${NC}"
    elif [ $TYPE_ERRORS -gt 0 ] || [ $NULL_ERRORS -gt 0 ] || [ $STATE_ERRORS -gt 0 ]; then
        echo -e "${RED}⚠️  تم اكتشاف أخطاء حرجة تحتاج إلى إصلاح فوري!${NC}"
    else
        echo -e "${YELLOW}⚠️  تم اكتشاف بعض التحذيرات، يُنصح بمراجعتها${NC}"
    fi
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    echo ""
}

# معالج للإشارات (Ctrl+C)
trap 'print_report; exit 0' INT TERM

# بدء المراقبة
if command -v flutter &> /dev/null; then
    # استخدام flutter run مع تسجيل اللوقز
    flutter run --observatory-port=8888 2>&1 | while IFS= read -r line; do
        echo "$line" | tee -a "$LOG_FILE"
        analyze_error "$line"
    done
else
    echo -e "${RED}❌ Flutter غير مثبت أو غير موجود في PATH${NC}"
    exit 1
fi

