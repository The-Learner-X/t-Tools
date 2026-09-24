#!/bin/bash

# --- 0) Install All Required Packages ---
echo -e "\033[1;36m[+] Updating Termux and installing required packages...\033[0m"
pkg update -y && pkg upgrade -y
pkg install figlet git pandoc typst pv libxslt xsltproc python libcairo nano imagemagick -y
pip install weasyprint


# --- 1) text (Interactive Engine UI) ---
cat << 'EOF' > $PREFIX/bin/text
#!/bin/bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

BROWSE_FILE() {
    echo -e "${CYAN}--- SELECT STORAGE LOCATION ---${NC}"
    echo -e "1) Internal Storage (/storage/emulated/0)"
    echo -e "2) Termux Home ($HOME)"
    read -p "Select storage [1-2]: " LOC
    [ "$LOC" == "1" ] && CUR_DIR="/storage/emulated/0" || CUR_DIR="$HOME"

    while true; do
        clear
        echo -e "${CYAN}Current Directory:${NC} ${YELLOW}$CUR_DIR${NC}\n"
        mapfile -t DIRS < <(find "$CUR_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)
        mapfile -t FILES < <(find "$CUR_DIR" -maxdepth 1 -mindepth 1 -type f ! -name '.*' | sort)

        echo -e "${GREEN}[ DIRECTORIES ]${NC}"
        idx=1
        for d in "${DIRS[@]}"; do
            echo -e "  $idx) 📁 $(basename "$d")"
            ((idx++))
        done

        echo -e "\n\033[1;35m[ FILES ]${NC}"
        f_start=$idx
        for f in "${FILES[@]}"; do
            echo -e "  $idx) 📄 $(basename "$f")"
            ((idx++))
        done

        echo -e "\n${YELLOW}--------------------------------------------------${NC}"
        echo -e " -> Type a ${GREEN}directory number${NC} to enter"
        echo -e " -> Type a ${GREEN}file number${NC} to select it"
        echo -e " -> Type ${CYAN}..${NC} to go up one directory"
        echo -e " -> Press ${RED}[Enter]${NC} without input to cancel/exit"
        echo -e "${YELLOW}--------------------------------------------------${NC}"
        read -p "Selection: " INP

        if [ -z "$INP" ]; then
            echo -e "${RED}[!] No path selected. Exiting...${NC}"
            return 1
        elif [ "$INP" == ".." ]; then
            CUR_DIR=$(dirname "$CUR_DIR")
        elif [[ "$INP" =~ ^[0-9]+$ ]]; then
            if [ "$INP" -lt "$f_start" ] && [ "$INP" -ge 1 ]; then
                CUR_DIR="${DIRS[$((INP-1))]}"
            elif [ "$INP" -ge "$f_start" ] && [ "$INP" -lt "$idx" ]; then
                SELECTED_FILE="${FILES[$((INP-f_start))]}"
                return 0
            fi
        fi
    done
}

RENDER_TEXT() {
    clear
    echo -e "${CYAN}--- GENERATE RED BANNER ---${NC}\n"
    echo -e "1) Type raw text manually"
    echo -e "2) Pick a file via File Browser"
    read -p "Choice [1-2]: " MODE

    if [ "$MODE" == "2" ]; then
        BROWSE_FILE || { read -p "Press [Enter] to return..."; return; }
        INPUT="$SELECTED_FILE"
    else
        read -p "Enter text: " INPUT
    fi

    if [ -z "$INPUT" ]; then
        echo -e "${RED}[!] Input is empty. Exiting...${NC}"
        read -p "Press [Enter] to return..."
        return
    fi

    echo -e "\n${YELLOW}[+] Output Banner:${NC}\n"
    if [ -f "$INPUT" ]; then
        echo -e "${RED}$(figlet -k -w100 -c < "$INPUT")${NC}"
    else
        echo -e "${RED}$(figlet -k -w100 -c "$INPUT")${NC}"
    fi
    echo ""
    read -p "Press [Enter] to continue..."
}

while true; do
    clear
    echo -e "${GREEN}======================================"${NC}
    echo -e "${CYAN}        TEXT BANNER ENGINE            "${NC}
    echo -e "${GREEN}======================================"${NC}
    echo -e "1) Generate Red FIGlet Banner"
    echo -e "2) Exit"
    echo -e "${GREEN}======================================"${NC}
    read -p "Select an option [1-2]: " CHOICE

    case $CHOICE in
        1) RENDER_TEXT ;;
        2) echo -e "${CYAN}Exiting text...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid selection!${NC}"; sleep 1 ;;
    esac
done
EOF
chmod +x $PREFIX/bin/text


# --- 2) text1 (Interactive Engine UI) ---
cat << 'EOF' > $PREFIX/bin/text1
#!/bin/bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

RENDER_TEXT1() {
    clear
    echo -e "${CYAN}--- GENERATE CYAN BANNER ---${NC}\n"
    read -p "Enter text: " INPUT

    if [ -z "$INPUT" ]; then
        echo -e "${RED}[!] No text entered. Exiting...${NC}"
        read -p "Press [Enter] to return..."
        return
    fi

    tmpfile=$(mktemp)
    echo "$INPUT" > "$tmpfile"
    echo -e "\n${YELLOW}[+] Output Banner:${NC}\n"
    echo -e "${CYAN}$(figlet -k -w55 -c < "$tmpfile")${NC}"
    rm -f "$tmpfile"
    echo ""
    read -p "Press [Enter] to continue..."
}

while true; do
    clear
    echo -e "${GREEN}======================================"${NC}
    echo -e "${CYAN}        TEXT1 BANNER ENGINE           "${NC}
    echo -e "${GREEN}======================================"${NC}
    echo -e "1) Generate Cyan FIGlet Banner"
    echo -e "2) Exit"
    echo -e "${GREEN}======================================"${NC}
    read -p "Select an option [1-2]: " CHOICE

    case $CHOICE in
        1) RENDER_TEXT1 ;;
        2) echo -e "${CYAN}Exiting text1...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid selection!${NC}"; sleep 1 ;;
    esac
done
EOF
chmod +x $PREFIX/bin/text1


# --- 3) pdf2 (Updated Engine Script) ---
cat << 'EOF' > $PREFIX/bin/pdf2
#!/bin/bash

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

BROWSE_FILE_PDF2() {
    local ext_pattern="$1"
    echo -e "${CYAN}--- SELECT STORAGE LOCATION ---${NC}"
    echo -e "1) Internal Storage (/storage/emulated/0)"
    echo -e "2) Termux Storage ($HOME)"
    read -p "Select storage [1-2]: " STORE_CHOICE

    case $STORE_CHOICE in
        1) CURRENT_DIR="/storage/emulated/0" ;;
        2) CURRENT_DIR="$HOME" ;;
        *) echo -e "${RED}[!] Invalid location selected. Exiting...${NC}"; return  ;;
    esac

    while true; do
        clear
        echo -e "${CYAN}Current Directory:${NC} ${YELLOW}$CURRENT_DIR${NC}\n"

        mapfile -t DIRS < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)
        mapfile -t FILES < <(eval "find \"$CURRENT_DIR\" -maxdepth 1 -mindepth 1 -type f \( $ext_pattern \) | sort")

        echo -e "${GREEN}[ DIRECTORIES ]${NC}"
        idx=1
        for d in "${DIRS[@]}"; do
            echo -e "  $idx) 📁 $(basename "$d")"
            ((idx++))
        done

        echo -e "\n\033[1;35m[ COMPATIBLE FILES ]${NC}"
        file_start_idx=$idx
        for f in "${FILES[@]}"; do
            echo -e "  $idx) 📄 $(basename "$f")"
            ((idx++))
        done

        if [ ${#FILES[@]} -eq 0 ]; then
            echo -e "  ${RED}(No compatible files found in this directory)${NC}"
        fi

        echo -e "\n${YELLOW}--------------------------------------------------${NC}"
        echo -e " -> Enter a directory number to open it"
        echo -e " -> Enter a file number to select target"
        echo -e " -> Type ${CYAN}..${NC} to go up one directory"
        echo -e " -> Press ${RED}[Enter]${NC} without input to cancel/exit"
        echo -e "${YELLOW}--------------------------------------------------${NC}"
        read -p "Your input: " USER_IN

        if [ -z "$USER_IN" ]; then
            echo -e "${RED}[!] Operation cancelled. No file selected.${NC}"
            return 1
        elif [ "$USER_IN" == ".." ]; then
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
        elif [[ "$USER_IN" =~ ^[0-9]+$ ]]; then
            if [ "$USER_IN" -lt "$file_start_idx" ] && [ "$USER_IN" -ge 1 ]; then
                dir_target="${DIRS[$((USER_IN-1))]}"
                [ -d "$dir_target" ] && CURRENT_DIR="$dir_target"
            elif [ "$USER_IN" -ge "$file_start_idx" ] && [ "$USER_IN" -lt "$idx" ]; then
                SELECTED_FILE="${FILES[$((USER_IN-file_start_idx))]}"
                return 0
            fi
        fi
    done
}

SHOW_HELP() {
    clear
    echo -e "${CYAN}=== PDF2 HELP & USAGE GUIDE ===${NC}\n"
    echo -e "${YELLOW}Option 1: Simple Text to PDF (.txt, .md)${NC}"
    echo -e "  - Converts raw text/markdown directly using Pandoc & Typst.\n"
    echo -e "${YELLOW}Option 2: Simple Result to PDF (HTML, XML, Bash+ANSI)${NC}"
    echo -e "  - Converts visual layouts & terminal outputs into styled PDF documents.\n"
    echo -e "${YELLOW}Output Directory:${NC}"
    echo -e "  - Output files save to ${CYAN}/storage/emulated/0/PDF2_Output/${NC}\n"
    read -p "Press [Enter] to return..."
}

CONVERT_TEXT_TO_PDF() {
    clear
    echo -e "${CYAN}--- SECTION A: TEXT TO PDF (FILE BROWSER) ---${NC}\n"
    BROWSE_FILE_PDF2 '-iname "*.txt" -o -iname "*.md"' || { read -p "Press [Enter] to return..."; return; }
    
    INPUT_FILE="$SELECTED_FILE"
    if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}[!] Selected file does not exist or was empty. Exiting...${NC}"
        read -p "Press [Enter] to return..."
        return
    fi

    echo -e "\n${GREEN}[+] Selected File:${NC} $INPUT_FILE"

    read -p "Enter output PDF name (e.g., output.pdf): " OUTPUT_PDF
    [ -z "$OUTPUT_PDF" ] && OUTPUT_PDF="text_output.pdf"

    mkdir -p /storage/emulated/0/PDF2_Output
    DEST_PATH="/storage/emulated/0/PDF2_Output/$OUTPUT_PDF"
    TEMP_TYP=$(mktemp --suffix=.typ)
    TEMP_PDF=$(mktemp --suffix=.pdf)

    echo -e "\n${YELLOW}[1/2] Converting markup structure...${NC}"
    pandoc "$INPUT_FILE" -f markdown -o "$TEMP_TYP"
    typst compile "$TEMP_TYP" "$TEMP_PDF"

    echo -e "${YELLOW}[2/2] Exporting to storage...${NC}"
    SIZE=$(stat -c%s "$TEMP_PDF")
    pv -s "$SIZE" "$TEMP_PDF" > "$DEST_PATH"

    if [ -f "$DEST_PATH" ]; then
        echo -e "\n${GREEN}[✓] Success! File saved to: ${DEST_PATH}${NC}\n"
    else
        echo -e "\n${RED}[×] Conversion failed.${NC}\n"
    fi

    rm -f "$TEMP_TYP" "$TEMP_PDF"
    read -p "Press [Enter] to continue..."
}

CONVERT_RESULT_TO_PDF() {
    clear
    echo -e "${CYAN}--- SECTION B: RESULT LAYOUT / ANSI TO PDF (FILE BROWSER) ---${NC}\n"
    
    if ! command -v xsltproc >/dev/null 2>&1; then
        echo -e "${RED}[ERROR] 'xsltproc' is not installed!${NC}"
        read -p "Press [Enter] to return..."
        return
    fi

    BROWSE_FILE_PDF2 '-iname "*.html" -o -iname "*.xml" -o -iname "*.sh" -o -iname "*.bash"' || { read -p "Press [Enter] to return..."; return; }
    INPUT_FILE="$SELECTED_FILE"

    if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}[!] Selected file does not exist or was empty. Exiting...${NC}"
        read -p "Press [Enter] to return..."
        return
    fi

    echo -e "\n${GREEN}[+] Selected File:${NC} $INPUT_FILE"

    read -p "Enter output PDF name (e.g., layout.pdf): " OUTPUT_PDF
    [ -z "$OUTPUT_PDF" ] && OUTPUT_PDF="layout_output.pdf"

    mkdir -p /storage/emulated/0/PDF2_Output
    DEST_PATH="/storage/emulated/0/PDF2_Output/$OUTPUT_PDF"
    TEMP_HTML=$(mktemp --suffix=.html)
    TEMP_PDF=$(mktemp --suffix=.pdf)

    echo -e "\n${YELLOW}[1/2] Processing document & ANSI styles...${NC}"
    
    if [[ "$INPUT_FILE" == *.sh || "$INPUT_FILE" == *.bash ]]; then
        python3 -c '
import sys, re, html, subprocess

input_file = sys.argv[1]
output_html_path = sys.argv[2]

try:
    res = subprocess.run(["bash", input_file], capture_output=True, text=True, timeout=5)
    content = res.stdout if res.stdout else res.stderr
except Exception:
    content = ""

if not content.strip():
    try:
        cmd = f"while IFS= read -r line || [ -n \"$line\" ]; do eval \"echo -e \\\"$line\\\"\"; done < {input_file}"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        content = res.stdout
    except Exception:
        with open(input_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

color_map = {
    "30": "#000000", "31": "#ff5555", "32": "#50fa7b", "33": "#f1fa8c",
    "34": "#bd93f9", "35": "#ff79c6", "36": "#8be9fd", "37": "#f8f8f2",
    "1;30": "#6272a4", "1;31": "#ff6e6e", "1;32": "#69ff94", "1;33": "#ffffa5",
    "1;34": "#d6acff", "1;35": "#ff92d0", "1;36": "#a4ffff", "1;37": "#ffffff"
}

def ansi_to_html(text):
    lines = text.splitlines()
    html_lines = []
    for line in lines:
        escaped = html.escape(line)
        def replace_ansi(match):
            code = match.group(1)
            if code in ("0", "0;0", ""): return "</span>"
            elif code in color_map: return f"<span style=\"color:{color_map[code]}; font-weight:bold;\">"
            elif code == "1": return "<span style=\"font-weight:bold;\">"
            return ""
        parsed = re.sub(r"(?:\x1b|\\033|\\e)\[([0-9;]*)m", replace_ansi, escaped)
        html_lines.append(f"<div class=\"line\">{parsed}</div>")
    return "\n".join(html_lines)

body_html = ansi_to_html(content)
full_html = f"""<!DOCTYPE html><html><head><style>
  @page {{ size: A4 portrait; margin: 1cm; }}
  body {{ background-color: #1e1e2e; color: #cdd6f4; font-family: "Courier New", monospace; font-size: 11pt; padding: 15px; white-space: pre-wrap; word-wrap: break-word; }}
  .line {{ line-height: 1.4; min-height: 1.2em; }}
</style></head><body>{body_html}</body></html>"""

with open(output_html_path, "w", encoding="utf-8") as f:
    f.write(full_html)
' "$INPUT_FILE" "$TEMP_HTML"

        weasyprint "$TEMP_HTML" "$TEMP_PDF" 2>/dev/null

    elif [[ "$INPUT_FILE" == *.xml ]]; then
        cat << 'XSL' > temp_transform.xsl
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/">
    <html><head><style>
      @page { size: A4; margin: 1cm; }
      body { font-family: sans-serif; background: #f4f5f7; padding: 15px; }
      div { box-sizing: border-box; }
      .LinearLayout, .RelativeLayout { display: flex; flex-direction: column; gap: 8px; border: 1px solid #dcdfe6; background: #ffffff; padding: 12px; margin-bottom: 10px; border-radius: 6px; }
      .TextView { color: #1a1a1a; font-size: 14px; margin: 4px 0; }
      .Button { display: inline-block; background-color: #6200ee; color: #ffffff; padding: 8px 16px; margin: 6px 0; border-radius: 4px; font-weight: bold; font-size: 13px; width: fit-content; text-align: center; }
    </style></head><body><xsl:apply-templates/></body></html>
  </xsl:template>
  <xsl:template match="*">
    <div class="{name()}" style="{@style}"><xsl:if test="@text"><xsl:value-of select="@text"/></xsl:if><xsl:apply-templates/></div>
  </xsl:template>
</xsl:stylesheet>
XSL
        xsltproc temp_transform.xsl "$INPUT_FILE" > "$TEMP_HTML"
        weasyprint "$TEMP_HTML" "$TEMP_PDF" 2>/dev/null
        rm -f temp_transform.xsl
    else
        weasyprint "$INPUT_FILE" "$TEMP_PDF" 2>/dev/null
    fi

    echo -e "${YELLOW}[2/2] Exporting output to storage...${NC}"
    SIZE=$(stat -c%s "$TEMP_PDF")
    pv -s "$SIZE" "$TEMP_PDF" > "$DEST_PATH"

    if [ -f "$DEST_PATH" ]; then
        echo -e "\n${GREEN}[✓] Render Complete! File saved to: ${DEST_PATH}${NC}\n"
    else
        echo -e "\n${RED}[×] Rendering failed.${NC}\n"
    fi

    rm -f "$TEMP_HTML" "$TEMP_PDF"
    read -p "Press [Enter] to continue..."
}

while true; do
    clear
    echo -e "${GREEN}======================================"${NC}
    echo -e "${CYAN}        PDF2 INTERACTIVE ENGINE       "${NC}
    echo -e "${GREEN}======================================"${NC}
    echo -e "1) Simple Text to PDF (Interactive Browser)"
    echo -e "2) Simple Result/ANSI to PDF (Interactive Browser)"
    echo -e "3) Help / Instructions"
    echo -e "4) Exit"
    echo -e "${GREEN}======================================"${NC}
    read -p "Select an option [1-4]: " CHOICE

    case $CHOICE in
        1) CONVERT_TEXT_TO_PDF ;;
        2) CONVERT_RESULT_TO_PDF ;;
        3) SHOW_HELP ;;
        4) echo -e "${CYAN}Exiting pdf2...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid selection!${NC}"; sleep 1 ;;
    esac
done
EOF
chmod +x $PREFIX/bin/pdf2


# --- 4) 2pdf (With Empty Path Guard) ---
cat << 'EOF' > $PREFIX/bin/2pdf
#!/bin/bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

BROWSE_FILE_2PDF() {
    clear
    echo -e "${CYAN}--- SELECT STORAGE LOCATION ---${RESET}"
    echo -e "1) Internal Storage (/storage/emulated/0)"
    echo -e "2) Termux Storage ($HOME)"
    read -p "Select storage [1-2]: " STORE_CHOICE

    case $STORE_CHOICE in
        1) CURRENT_DIR="/storage/emulated/0" ;;
        2) CURRENT_DIR="$HOME" ;;
        *) echo -e "${RED}[!] Invalid location selected. Exiting...${RESET}"; return 1 ;;
    esac

    while true; do
        clear
        echo -e "${CYAN}Current Directory:${RESET} ${YELLOW}$CURRENT_DIR${RESET}\n"

        mapfile -t DIRS < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)
        mapfile -t FILES < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f ! -name '.*' | sort)

        echo -e "${GREEN}[ DIRECTORIES ]${RESET}"
        idx=1
        for d in "${DIRS[@]}"; do
            echo -e "  $idx) 📁 $(basename "$d")"
            ((idx++))
        done

        echo -e "\n\033[1;35m[ FILES ]${RESET}"
        file_start_idx=$idx
        for f in "${FILES[@]}"; do
            echo -e "  $idx) 📄 $(basename "$f")"
            ((idx++))
        done

        echo -e "\n${YELLOW}--------------------------------------------------${RESET}"
        echo -e " -> Enter a directory number to open it"
        echo -e " -> Enter a file number to select target input"
        echo -e " -> Type ${CYAN}..${RESET} to go up one directory"
        echo -e " -> Press ${RED}[Enter]${RESET} without input to cancel/exit"
        echo -e "${YELLOW}--------------------------------------------------${RESET}"
        read -p "Your input: " USER_IN

        if [ -z "$USER_IN" ]; then
            echo -e "${RED}[!] No path selected. Exiting...${RESET}"
            return 1
        elif [ "$USER_IN" == ".." ]; then
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
        elif [[ "$USER_IN" =~ ^[0-9]+$ ]]; then
            if [ "$USER_IN" -lt "$file_start_idx" ] && [ "$USER_IN" -ge 1 ]; then
                dir_target="${DIRS[$((USER_IN-1))]}"
                [ -d "$dir_target" ] && CURRENT_DIR="$dir_target"
            elif [ "$USER_IN" -ge "$file_start_idx" ] && [ "$USER_IN" -lt "$idx" ]; then
                FILE="${FILES[$((USER_IN-file_start_idx))]}"
                return 0
            fi
        fi
    done
}

BROWSE_FILE_2PDF || exit 1

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo -e "${RED}[!] Selected file does not exist or is empty. Exiting...${RESET}"
    exit 1
fi

TMP_TYP=$(mktemp --suffix=.typ)
TMP_PDF=$(mktemp --suffix=.pdf)

(
    { echo '```'; cat "${FILE}"; echo '```'; } | pandoc -f markdown -o "$TMP_TYP"
    typst compile "$TMP_TYP" "$TMP_PDF"
) >/dev/null 2>&1 &

pid=$!
spin='-\|/'
i=0
echo -ne "\033[1;33m[+] Compiling PDF from $(basename "$FILE")...  \033[0m"

while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    echo -ne "\b${spin:$i:1}"
    sleep 0.1
done

if [ -f "$TMP_PDF" ]; then
    echo -e "\b\033[1;32mDone!\033[0m"
else
    echo -e "\b\033[1;31mFailed!\033[0m Check compilation syntax."
    rm -f "$TMP_TYP" "$TMP_PDF"
    exit 1
fi

echo "==================================="
read -p "Enter pdf Name (e.g. output.pdf): " pdfName
echo "==================================="
[ -z "$pdfName" ] && pdfName="output.pdf"

Storage="/storage/emulated/0/T2pdf/"
Termux="/data/data/com.termux/files/home/"
red='\033[1;31m'
grbg='\033[42;30m'
Reset='\033[0m'
cyn='\033[1;36m'

mkdir -p "$Storage"
echo "==================================="
echo -e "\nChoose Location to save File:"
echo "==================================="
echo -e "1) Internal Storage ${cyn}($Storage)${Reset}"
echo "==================================="
echo -e "2) Termux Home ${cyn}($Termux)${Reset}"
echo "==================================="
read -p "Enter choice [1 or 2]: " LOCATION

case "$LOCATION" in
  1)
     echo -e "\033[1;33m[+] Transferring file to Internal Storage...\033[0m"
     pv "$TMP_PDF" > "$Storage/$pdfName" 2>&1
     echo -e "File saved in ${red}${Storage}${Reset} with name ${grbg}${pdfName}${Reset}"
     ;;
  2)
     echo -e "\033[1;33m[+] Transferring file to Termux Home...\033[0m"
     pv "$TMP_PDF" > "$Termux/$pdfName" 2>&1
     echo -e "File saved in ${red}${Termux}${Reset} with name ${grbg}${pdfName}${Reset}"
     ;;
  *)
     echo -e "${red}Invalid option!${Reset} Leaving file in current directory."
     pv "$TMP_PDF" > "./$pdfName" 2>&1
     ;;
esac
echo "==================================="
rm -f "$TMP_TYP" "$TMP_PDF"
EOF
chmod +x $PREFIX/bin/2pdf


# --- 5) Cleaned Termux Binary ($PREFIX/bin/termux - No Banner Setup) ---
cat << 'EOF' > $PREFIX/bin/termux
#!/bin/bash
apt update && apt upgrade -y
termux-setup-storage
pkg install figlet git nano -y

mkdir -p ~/.termux
nano ~/.termux/termux.properties

termux-reload-settings
EOF
chmod +x $PREFIX/bin/termux


# --- 6) imgtools Binary (With Empty Selection Guard) ---
cat << 'EOF' > $PREFIX/bin/imgtools
#!/bin/bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
    echo -e "${RED}[!] ImageMagick is not installed. Installing...${RESET}"
    pkg install imagemagick -y
fi

OUT_DIR="/storage/emulated/0/ImgTools_Output"
mkdir -p "$OUT_DIR"

BROWSE_SINGLE_IMAGE() {
    clear
    echo -e "${CYAN}--- SELECT STORAGE LOCATION ---${RESET}"
    echo -e "1) Internal Storage (/storage/emulated/0)"
    echo -e "2) Termux Storage ($HOME)"
    read -p "Select storage [1-2]: " STORE_CHOICE

    case $STORE_CHOICE in
        1) CURRENT_DIR="/storage/emulated/0" ;;
        2) CURRENT_DIR="$HOME" ;;
        *) echo -e "${RED}[!] Invalid location selected. Exiting...${RESET}"; return 1 ;;
    esac

    while true; do
        clear
        echo -e "${CYAN}Current Directory:${RESET} ${YELLOW}$CURRENT_DIR${RESET}\n"

        mapfile -t DIRS < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)
        mapfile -t FILES < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" \) | sort)

        echo -e "${GREEN}[ DIRECTORIES ]${RESET}"
        idx=1
        for d in "${DIRS[@]}"; do
            echo -e "  $idx) 📁 $(basename "$d")"
            ((idx++))
        done

        echo -e "\n\033[1;35m[ IMAGE FILES ]${RESET}"
        file_start_idx=$idx
        for f in "${FILES[@]}"; do
            echo -e "  $idx) 🖼️  $(basename "$f")"
            ((idx++))
        done

        echo -e "\n${YELLOW}--------------------------------------------------${RESET}"
        echo -e " -> Enter a directory number to open it"
        echo -e " -> Enter an image file number to select it"
        echo -e " -> Type ${CYAN}..${RESET} to go up one directory"
        echo -e " -> Press ${RED}[Enter]${RESET} without input to cancel/exit"
        echo -e "${YELLOW}--------------------------------------------------${RESET}"
        read -p "Your input: " USER_IN

        if [ -z "$USER_IN" ]; then
            echo -e "${RED}[!] Operation cancelled. No image path selected.${RESET}"
            return 1
        elif [ "$USER_IN" == ".." ]; then
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
        elif [[ "$USER_IN" =~ ^[0-9]+$ ]]; then
            if [ "$USER_IN" -lt "$file_start_idx" ] && [ "$USER_IN" -ge 1 ]; then
                dir_target="${DIRS[$((USER_IN-1))]}"
                [ -d "$dir_target" ] && CURRENT_DIR="$dir_target"
            elif [ "$USER_IN" -ge "$file_start_idx" ] && [ "$USER_IN" -lt "$idx" ]; then
                SINGLE_IMAGE="${FILES[$((USER_IN-file_start_idx))]}"
                return 0
            fi
        fi
    done
}

SELECT_IMAGES_INTERACTIVE() {
    clear
    echo -e "${CYAN}--- SELECT STORAGE LOCATION ---${RESET}"
    echo -e "1) Internal Storage (/storage/emulated/0)"
    echo -e "2) Termux Storage ($HOME)"
    read -p "Select storage [1-2]: " STORE_CHOICE

    case $STORE_CHOICE in
        1) CURRENT_DIR="/storage/emulated/0" ;;
        2) CURRENT_DIR="$HOME" ;;
        *) echo -e "${RED}[!] Invalid location selected. Exiting...${RESET}"; sleep 1; return 1 ;;
    esac

    SELECTED_FILES=()

    while true; do
        clear
        echo -e "${CYAN}Current Directory:${RESET} ${YELLOW}$CURRENT_DIR${RESET}\n"

        mapfile -t DIRS < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)
        mapfile -t FILES < <(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" \) | sort)

        echo -e "${GREEN}[ DIRECTORIES ]${RESET}"
        idx=1
        for d in "${DIRS[@]}"; do
            echo -e "  $idx) 📁 $(basename "$d")"
            ((idx++))
        done

        echo -e "\n\033[1;35m[ IMAGE FILES ]${RESET}"
        file_start_idx=$idx
        for f in "${FILES[@]}"; do
            echo -e "  $idx) 🖼️  $(basename "$f")"
            ((idx++))
        done

        echo -e "\n${YELLOW}--------------------------------------------------${RESET}"
        echo -e " -> Enter numbers to pick images (e.g. ${GREEN}5 6 8${RESET} or ${GREEN}*${RESET} for all images)"
        echo -e " -> Enter a directory number to open it"
        echo -e " -> Type ${CYAN}..${RESET} to go up one directory"
        echo -e " -> Type ${RED}done${RESET} when finished selecting"
        echo -e " -> Press ${RED}[Enter]${RESET} without input to cancel/exit"
        echo -e "${YELLOW}--------------------------------------------------${RESET}"
        read -p "Your input: " USER_IN

        if [ -z "$USER_IN" ]; then
            echo -e "${RED}[!] Selection cancelled.${RESET}"
            return 1
        elif [ "$USER_IN" == "done" ]; then
            break
        elif [ "$USER_IN" == ".." ]; then
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
        elif [ "$USER_IN" == "*" ]; then
            for f in "${FILES[@]}"; do
                SELECTED_FILES+=("$f")
            done
            echo -e "${GREEN}[+] Added all images in current folder!${RESET}"
            sleep 1
        else
            for item in $USER_IN; do
                if [[ "$item" =~ ^[0-9]+$ ]]; then
                    if [ "$item" -lt "$file_start_idx" ] && [ "$item" -ge 1 ]; then
                        dir_target="${DIRS[$((item-1))]}"
                        if [ -d "$dir_target" ]; then
                            CURRENT_DIR="$dir_target"
                            break
                        fi
                    elif [ "$item" -ge "$file_start_idx" ] && [ "$item" -lt "$idx" ]; then
                        file_target="${FILES[$((item-file_start_idx))]}"
                        SELECTED_FILES+=("$file_target")
                        echo -e "${GREEN}[+] Selected: $(basename "$file_target")${RESET}"
                    fi
                fi
            done
            sleep 1
        fi
    done

    if [ ${#SELECTED_FILES[@]} -eq 0 ]; then
        echo -e "${RED}[!] No images were selected. Exiting operation...${RESET}"
        return 1
    fi
}

while true; do
    clear
    echo -e "${CYAN}======================================"${RESET}
    echo -e "${YELLOW}        IMGTOOLS UTILITY ENGINE        "${RESET}
    echo -e "${CYAN}======================================"${RESET}
    echo -e "1) Convert Image(s) to PDF (Interactive Explorer)"
    echo -e "2) Convert Image Format (JPG/PNG/WEBP/etc.)"
    echo -e "3) Resize Image"
    echo -e "4) Compress / Quality Adjust"
    echo -e "5) Rotate Image"
    echo -e "6) Exit"
    echo -e "${CYAN}======================================"${RESET}
    read -p "Select an option [1-6]: " CHOICE

    case $CHOICE in
        1)
            SELECT_IMAGES_INTERACTIVE || { read -p "Press [Enter] to return..."; continue; }

            read -p "Enter Output PDF Filename (e.g. document.pdf): " OUT_NAME
            [ -z "$OUT_NAME" ] && OUT_NAME="images_combined.pdf"
            [[ "$OUT_NAME" != *.pdf ]] && OUT_NAME="${OUT_NAME}.pdf"
            
            echo -e "${YELLOW}[+] Scaling and converting ${#SELECTED_FILES[@]} selected image(s) to A4 PDF...${RESET}"
            convert "${SELECTED_FILES[@]}" -density 72 -resize 595x842\> -gravity center -extent 595x842 "$OUT_DIR/$OUT_NAME" 2>/dev/null
            
            if [ -f "$OUT_DIR/$OUT_NAME" ]; then
                echo -e "${GREEN}[✓] PDF created successfully at $OUT_DIR/$OUT_NAME${RESET}"
            else
                echo -e "${RED}[×] PDF generation failed!${RESET}"
            fi
            read -p "Press [Enter] to continue..."
            ;;
        2)
            BROWSE_SINGLE_IMAGE || { read -p "Press [Enter] to return..."; continue; }
            IN_FILE="$SINGLE_IMAGE"
            [ -z "$IN_FILE" ] && continue
            read -p "Enter output filename with extension (e.g. output.png): " OUT_NAME
            convert "$IN_FILE" "$OUT_DIR/$OUT_NAME"
            echo -e "${GREEN}[✓] Saved to $OUT_DIR/$OUT_NAME${RESET}"
            read -p "Press [Enter] to continue..."
            ;;
        3)
            BROWSE_SINGLE_IMAGE || { read -p "Press [Enter] to return..."; continue; }
            IN_FILE="$SINGLE_IMAGE"
            [ -z "$IN_FILE" ] && continue
            read -p "Enter dimensions (e.g., 800x600 or 50%): " RES
            read -p "Enter output filename: " OUT_NAME
            convert "$IN_FILE" -resize "$RES" "$OUT_DIR/$OUT_NAME"
            echo -e "${GREEN}[✓] Saved to $OUT_DIR/$OUT_NAME${RESET}"
            read -p "Press [Enter] to continue..."
            ;;
        4)
            BROWSE_SINGLE_IMAGE || { read -p "Press [Enter] to return..."; continue; }
            IN_FILE="$SINGLE_IMAGE"
            [ -z "$IN_FILE" ] && continue
            read -p "Enter quality percentage (e.g., 75): " QUAL
            read -p "Enter output filename: " OUT_NAME
            convert "$IN_FILE" -quality "$QUAL%" "$OUT_DIR/$OUT_NAME"
            echo -e "${GREEN}[✓] Saved to $OUT_DIR/$OUT_NAME${RESET}"
            read -p "Press [Enter] to continue..."
            ;;
        5)
            BROWSE_SINGLE_IMAGE || { read -p "Press [Enter] to return..."; continue; }
            IN_FILE="$SINGLE_IMAGE"
            [ -z "$IN_FILE" ] && continue
            read -p "Enter rotation degrees (90, 180, 270): " DEG
            read -p "Enter output filename: " OUT_NAME
            convert "$IN_FILE" -rotate "$DEG" "$OUT_DIR/$OUT_NAME"
            echo -e "${GREEN}[✓] Saved to $OUT_DIR/$OUT_NAME${RESET}"
            read -p "Press [Enter] to continue..."
            ;;
        6)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${RESET}"
            sleep 1
            ;;
    esac
done
EOF
chmod +x $PREFIX/bin/imgtools


# --- 7) Interactive tTools Menu & ANSI Tables ---
cat << 'display' > $PREFIX/bin/tTools
#!/bin/bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

SHOW_CMD_TABLES() {
    clear
    echo -e "${BOLD}${MAGENTA}--- 6 COMMAND INDIVIDUAL SPECIFICATION TABLES ---${RESET}\n"

    # Table 1: text
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 1: text${RESET}                                                          ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Red Large Text & File Banner Engine                          ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}File Navigation${RESET}    ${CYAN}|${RESET} Built-in File Browser OR manual input                       ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Visual Output${RESET}      ${CYAN}|${RESET} Red ANSI FIGlet text with kerning (-k, Width: 100, Center)  ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    # Table 2: text1
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 2: text1${RESET}                                                         ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Cyan Kerning Text Banner Engine                             ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Input Types${RESET}        ${CYAN}|${RESET} Raw text string via temporary file pipe                      ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Visual Output${RESET}      ${CYAN}|${RESET} Cyan ANSI FIGlet text with tight kerning (-k, Width: 55)   ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    # Table 3: pdf2
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 3: pdf2${RESET}                                                          ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Interactive Layout & Visual Document PDF Engine             ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}File Navigation${RESET}    ${CYAN}|${RESET} Built-in Interactive Directory & Extension Explorer          ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Output Target${RESET}      ${CYAN}|${RESET} /storage/emulated/0/PDF2_Output/                             ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    # Table 4: 2pdf
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 4: 2pdf${RESET}                                                          ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Code Block & Text PDF Exporter with Browser                 ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}File Navigation${RESET}    ${CYAN}|${RESET} Built-in File Browser                                       ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Output Target${RESET}      ${CYAN}|${RESET} Choice: Internal Storage (/storage/emulated/0/T2pdf/) OR Home${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    # Table 5: termux
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 5: termux${RESET}                                                        ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Package Update & Properties Editor                           ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Key Actions${RESET}        ${CYAN}|${RESET} Opens nano for properties & reloads settings                 ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    # Table 6: imgtools
    echo -e "${CYAN}+---------------------------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${YELLOW}COMMAND 6: imgtools${RESET}                                                      ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Primary Function${RESET}   ${CYAN}|${RESET} Image-to-PDF, Conversion, Resizing & Compression            ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}File Navigation${RESET}    ${CYAN}|${RESET} Multi-Image & Single-Image Interactive File Browser         ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} ${WHITE}Output Target${RESET}      ${CYAN}|${RESET} /storage/emulated/0/ImgTools_Output/                         ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------------------------------+${RESET}\n"

    read -p "$(echo -e ${WHITE}"Press [Enter] to return to menu..."${RESET})"
}

SHOW_COMPARISONS() {
    clear
    echo -e "${BOLD}${MAGENTA}--- COMPARISON TABLES FOR SIMILAR LOOKING COMMANDS ---${RESET}\n"

    # Comparison 1: text vs text1
    echo -e "${YELLOW}[ COMPARISON 1: text vs text1 ]${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${WHITE}FEATURE${RESET}            ${CYAN}|${RESET} ${BOLD}${GREEN}text${RESET}                               ${CYAN}|${RESET} ${BOLD}${CYAN}text1${RESET}                              ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} Output Color       ${CYAN}|${RESET} Red (\033[31mRed\033[0m)                           ${CYAN}|${RESET} Cyan (\033[36mCyan\033[0m)                         ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} Width & Spacing     ${CYAN}|${RESET} 100 Width, Kerning Enabled (-k)     ${CYAN}|${RESET} 55 Width, Kerning Enabled (-k)      ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} File Browser       ${CYAN}|${RESET} Included                            ${CYAN}|${RESET} Direct manual text prompt           ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}\n"

    # Comparison 2: pdf2 vs 2pdf
    echo -e "${YELLOW}[ COMPARISON 2: pdf2 vs 2pdf ]${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} ${BOLD}${WHITE}FEATURE${RESET}            ${CYAN}|${RESET} ${BOLD}${GREEN}pdf2${RESET}                               ${CYAN}|${RESET} ${BOLD}${CYAN}2pdf${RESET}                              ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}"
    echo -e "${CYAN}|${RESET} Core Purpose       ${CYAN}|${RESET} Full Layout & Visual PDF Rendering  ${CYAN}|${RESET} Raw Source Code Export to PDF       ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} File Browser       ${CYAN}|${RESET} Filtered extension file browser     ${CYAN}|${RESET} Global file browser                 ${CYAN}|${RESET}"
    echo -e "${CYAN}|${RESET} Engine Tech        ${CYAN}|${RESET} Typst + xsltproc + Python + Weasy   ${CYAN}|${RESET} Pandoc + Typst engine               ${CYAN}|${RESET}"
    echo -e "${CYAN}+--------------------+------------------------------------+------------------------------------+${RESET}\n"

    read -p "$(echo -e ${WHITE}"Press [Enter] to return to menu..."${RESET})"
}

while true; do
    clear
    echo -e "${CYAN}=====================================================${RESET}"
    echo -e "${BOLD}${MAGENTA}                tTools Control Center                ${RESET}"
    echo -e "${CYAN}=====================================================${RESET}"
    echo -e "${GREEN} 1)${RESET} Display Text / File          ${WHITE}(text)${RESET}"
    echo -e "${GREEN} 2)${RESET} Display Saved Text           ${WHITE}(text1)${RESET}"
    echo -e "${GREEN} 3)${RESET} Interactive Engine           ${WHITE}(pdf2)${RESET}"
    echo -e "${GREEN} 4)${RESET} Legacy Code Block Converter  ${WHITE}(2pdf)${RESET}"
    echo -e "${GREEN} 5)${RESET} Termux Setup & Properties    ${WHITE}(termux)${RESET}"
    echo -e "${GREEN} 6)${RESET} Image Utility Engine         ${WHITE}(imgtools)${RESET}"
    echo -e "${GREEN} 7)${RESET} View 6 Command Specification Tables"
    echo -e "${GREEN} 8)${RESET} View Command Comparison Tables (text/text1, pdf2/2pdf)"
    echo -e "${RED} 9)${RESET} Exit"
    echo -e "${CYAN}=====================================================${RESET}"
    read -p "$(echo -e ${YELLOW}"Select an option [1-9]: "${RESET})" CHOICE

    case "$CHOICE" in
        1) clear; $PREFIX/bin/text ;;
        2) clear; $PREFIX/bin/text1 ;;
        3) clear; pdf2 ;;
        4) clear; 2pdf ;;
        5) clear; $PREFIX/bin/termux ;;
        6) clear; $PREFIX/bin/imgtools ;;
        7) SHOW_CMD_TABLES ;;
        8) SHOW_COMPARISONS ;;
        9) echo -e "${YELLOW}Exiting tTools... Goodbye!${RESET}"; exit 0 ;;
        *) echo -e "${RED}Invalid selection! Please pick 1-9.${RESET}"; sleep 1.5 ;;
    esac
done
display
chmod +x $PREFIX/bin/tTools

# Run tTools cleanly
$PREFIX/bin/tTools
