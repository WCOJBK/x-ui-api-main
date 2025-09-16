#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}=== 3X-UI Enhanced API 编译测试 ===${NC}"
echo ""

# 清理之前的构建
echo -e "${YELLOW}清理之前的构建文件...${NC}"
go clean

# 检查Go环境
echo -e "${BLUE}检查Go环境...${NC}"
go version

# 更新依赖
echo -e "${BLUE}更新Go模块依赖...${NC}"
go mod tidy

# 尝试编译
echo -e "${BLUE}开始编译测试...${NC}"
go build -o x-ui-test main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${GREEN}✅ 生成的二进制文件: x-ui-test${NC}"
    ls -la x-ui-test
    
    # 清理测试文件
    rm -f x-ui-test
    
    echo ""
    echo -e "${GREEN}🎉 所有编译错误已修复！${NC}"
    echo -e "${BLUE}现在可以正常部署增强版本了${NC}"
else
    echo -e "${RED}❌ 编译失败，请检查错误信息${NC}"
    exit 1
fi
