#! /bin/bash
debugLevel=INFO # NOTE > INFO > WARN > ERR

declare -A columnTR # Não acentuar. Usar minúsculas. Regex pode ser usado. Ordem será preservada.
columnTR[ticketID]="^id$|ticketid" # Chave mandatória. Permite alterar valores associados.
columnTR[pipeline]="helpdesk|fila"
columnTR[client]="client|store|loja"
columnTR[occurrMoment]="occurence|ocorrencia"
columnTR[ticketMoment]="creation|criacao"
columnTR[priority]="priority|prioridade"
columnTR[operationsError]="operation.*err|err.*operacional|err.*operacao"
columnTR[status]="status|estado"
columnTR[subject]="subject|assunto"
columnTR[category]="category|categoria"
columnTR[segment]="localizacao"
columnTR[group]="#" # Não alterar: para fins de impressão. Permite reordenar.
columnTR[service]="#" # Não alterar: para fins de impressão. Permite reordenar.
columnTR[solutionMoment]="solution.*date|data.*solucao"
columnTR[closeMoment]="close.*date|data.*fechamento"
columnTR[agent]="agent"

declare -A groupTR
groupTR[COD]="COD"
groupTR[DLV]="DLV|Deliver|Recall"
groupTR[Printer]="[ie]mprim[ei]|[ie]mpress"
groupTR[Pinpad]="pin|trava.*passa.*cart"
groupTR[NGK]="t[oó]te[mn]|NGK|CSO|POS(2[1-9]|30)"
groupTR[TAP]="TAP|Tablet"
groupTR[ORB]="ORB|Dual Point"
groupTR[MCC]="MCC|Caf[ée]|POS6[1-9]"
groupTR[DT]="DT|drive|face|POS7[1-9]"
groupTR[CK]="CK|Cold|Dessert|POS4[1-9]"
groupTR[FC]="FC|POS|Balc[aã]o|BALC[0-9]"
groupTR[Production]="Produ[cç]|Prim[áa]r|Sec[uo]nd[áa]r|Failover"
groupTR[MFY]="MFY|Pedidos.*cozinha"
groupTR[OAT]="OAT"
groupTR[KVS]="KVS|Monitor"
groupTR[WAY]="WAY|GSC|station"
groupTR[Drawer]="Cash|Drawer|Gaveta"

declare -A serviceTR # Ordem será preservada. Evitar os termos individuais Aplicação > Falha Erro.
serviceTR["Instrução GPRS"]="solicita.*cart[ãa]o.*GPRS|GPRS.*solicita.*cat[ãa]o"
serviceTR["Instrução BOG"]="BOG|cupo[mn]|smart"
serviceTR["Instrução DLV"]="(falha|erro).*(puxa|recal)|pedido"
serviceTR["PGTO Digital"]="(pgto|pagamento).*digital|mercado.*(pago|paggo)"
serviceTR["Produto/Outage"]="outage|falha.*exib.*prod|prod.*(inactive|inativo)"
serviceTR["Infra/Comunicação"]="comunica|produ[çc][ãa]o.*offline"
serviceTR["WAY/Produção"]="WAY|GSC|MCC.*OAT|Produ[çc][ãa]o|Prim[áa]ria|senha.*indev"
serviceTR["Cadastro/Vendas"]="(endere[çc]o|logradouro|dado).*fiscal|(altera|imprim[ei]).*(nome|endere[çc]o|logradouro|CNPJ|IE|PROCON|dados)"
serviceTR["Apply Update"]="apply.*update|UPDT|(aplica|atualiza).*pacote|setup"
serviceTR["POS Layout"]="(menu|remo).*(menu|mcc)|(des|h)abilita.*tela"
serviceTR["Nó reiniciando"]="inicia"
serviceTR["Cadastro de Preço"]="pre[çc]o.*incorreto"
serviceTR["Table Service"]="Table.*Service|serv.*mesa"
serviceTR["Business Day"]="abertura"
serviceTR["Cancelamento Vendas"]="cancel.*venda"
serviceTR["Roteamento"]="roteamento|n[ãa]o.*envia.*pedido|(falha|KVS).*exib.*pedido"
serviceTR["Performance"]="travando|lent[ao]|lentid[ãa]o"
serviceTR["FLEX/Incorporação"]="flex|leitura.*vendas|falha.*STLD|relat[óo]rio|sangria"
serviceTR["Topology/Install"]="remo[çc][aã]o|remover|excluir|instala|baixa.*imagem"
serviceTR["Cash Drawer"]="cash|drawer|abre"
serviceTR["Pinpad"]="(falha|trava).*cart[ãa]o"
serviceTR["Card reader"]="cart[ãa]o*inv[áa]lido"
serviceTR["Impressora"]="config.*impressora|(impress[ãa]o|impressora).*(erro|offline|funciona)|pic\?k\?list"
serviceTR["Relatório"]="relat[óo]rio|imprime|gera|extra[çc][ãa]o|extrair"
serviceTR["Nó Bloqueado"]="POS.*Bloqu[ei]ado"
serviceTR["COD"]="erro.*COD"

srcFile=$1
tmpCSV=/tmp/invgate.$$.csv

IFS=$'\n'
#set -x

fDate() {
	local d=$(echo $1 | sed 's/ .*//')
	local t=$(echo $1 | sed 's/.* //')

	d="$(echo $d | cut -d'/' -f3)-$(echo $d | cut -d'/' -f2)-$(echo $d | cut -d'/' -f1)"
	h=$(echo $t | cut -d':' -f1); [ ${#h} == 1 ] && t="0${t}"; t=$(echo $t | sed 's/\([0-2][0-9]:[0-5][0-9]\).*/\1/')

	[[ "$t" =~ ^[0-2][0-9]:[0-5][0-9]$ ]] && t=" $t"
	echo -e "$d$t"
}

declare -A debugInt
debugInt[NOTE]=0
debugInt[INFO]=1
debugInt[WARN]=2
debugInt[ERR]=3
[ -n "$debugLevel" ] && [ -n "${debugInt[$debugLevel]}" ] && debugLevel=${debugInt[$debugLevel]} || debugLevel=0
logIt() {
	msg=$1
	doEcho=true

	if [ -n "$debugLevel" ] && [[ "$msg" =~ "::" ]]; then
		msgDebug=${debugInt[$(echo $msg | sed 's/ ::.*//')]}
		[ ${msgDebug:-9} -lt $debugLevel ] && doEcho=false
	fi

	$doEcho && echo -e $1
}

[ ! -e "$srcFile" ] && logIt "ERR :: Inform a valid CSV ou XLSX file as a parameter. Abort." && exit 1

dstCSV=$(echo $srcFile | sed 's/\..*/.interpreted.csv/')
dstPNG=$(echo $srcFile | sed 's/\..*/.interpreted.png/')

declare -a printOrder
for L in $(grep ^columnTR $0); do
	key=$(echo $L | sed 's/^columnTR\[\?\(.*\)"\?\]=.*/\1/')
	printOrder+=( "$key" )
done

declare -a serviceOrder
for L in $(grep ^serviceTR $0); do
	key=$(echo $L | sed 's/^serviceTR\["\?\(.*\)"\?\"]=.*/\1/')
	serviceOrder+=( "$key" )
done

[[ $srcFile =~ xlsx$ ]] && xlsx2csv -d ';' $srcFile > $tmpCSV || cat $srcFile | iconv -f ISO-8859-1 -t UTF-8 | dos2unix > $tmpCSV
origCount=$(wc -l $tmpCSV | sed 's/\([0-9]\+\) .*/\1/g')

declare -A ticketsPerGroup
declare -A ticketsPerService
declare -A ticketsPerClient
declare -A clientTickets

declare -A translateService

regCount=0
declare -A colIndex
for L in $(cat $tmpCSV); do
	if [ $regCount -eq 0 ]; then
		i=0
		L=$(echo $L | sed -e 's/^;/ ;/' -e 's/;;/; ;/g' -e 's/;$/; /')
		for label in $(echo $L | tr ';' '\n'); do
			((i++))
			col=$(echo $label | unaccent UTF-8 | sed 's/[^A-Za-z]//g' | tr 'A-Z' 'a-z')
	
			skip=false
			[ -z "$col" ] && skip=true && logIt "INFO :: Position [$i] has no column name."; $skip && continue
			[ -n "${colIndex[$col]}" ] && skip=true && logIt "WARN :: Column [$key] already set."; $skip && continue

			mapAs=
			for key in "${!columnTR[@]}"; do
				[ -n "$(echo $col | grep -i -E ${columnTR[$key]})" ] && mapAs=$key && break
			done

			if [ -n "$mapAs" ]; then
				colIndex[$mapAs]=$i
				logIt "NOTE :: Mapped [$label] as [$mapAs] on position [$i]."
			else
				logIt "INFO :: Ignored column on position [$i]: [$label]."
			fi
		done

		[ ${#colIndex[@]} -eq 0 ] && logIt "ERR :: No columns found on file [$srcFile]. Abort." && exit 2

		rm -f $dstCSV
		plus1=false
		logIt "NOTE :: Generating file: $dstCSV..."
		for key in "${printOrder[@]}"; do
			$plus1 && echo -n ";" >> $dstCSV || plus1=true
			echo -n $key >> $dstCSV
		done; echo >> $dstCSV

		((regCount++))
		continue
	fi

	#unset valOf
	declare -A valOf
	for key in "${!colIndex[@]}"; do
		val=$(echo $L | cut -d';' -f${colIndex[$key]})

		case $key in
			ticketID)
				val=$(echo $val | sed 's/[^0-9]//g') ;;
			client)
				val=$(echo $val | sed 's/[^A-Za-z0-9]//g' | sed 's/\(.\{3\}\).*/\1/') ;;
			pipeline)
				[[ "$val" =~ "N2 NP6 CAP" ]] && val=NP6 || ( [[ "$val" =~ "N2 RFM CAP" ]] && val=RFM ) ;;
			subject)
				val=$(echo $val | sed 's/[^A-Za-z0-9 ,\._-]//g' | sed 's/.*SD-[0-9]\{6,7\} //' | sed -e 's/^ \+//' -e 's/ \+$//' -e 's/ \+/ /g') ;;
			category)
				val=$(echo $val | sed 's/.*Restaurante Brasil > //') ;;
		esac

		[[ $key =~ Moment ]] && [[ -n $val ]] && val=$(fDate $val)
		valOf[$key]=$val
	done
	
	( [ -z "${valOf[ticketID]}" ] || [ -z "${valOf[subject]}" ] || [ -z "${valOf[ticketMoment]}" ] ) && continue
	[[ ${valOf[client]} =~ [^A-Z] ]] && valOf[client]=$(echo ${valOf[subject]} | sed 's/[^A-Z]//g' | sed 's/\(.\{3\}\).*/\1/')

	valOf[group]=Other
	for key in "${!groupTR[@]}"; do
		[ -n "$(echo ${valOf[segment]} | grep -i -E ${groupTR[$key]})" ] && valOf[group]=$key
		[ -n "$(echo ${valOf[subject]} | grep -i -E ${groupTR[$key]})" ] && valOf[group]=$key && break
		# We trust on subject more than in the chosen segment. Hope that improves one day.
	done

	valOf[service]=Other
	for key in "${serviceOrder[@]}"; do
		[ -n "$(echo ${valOf[category]} | grep -i -E ${serviceTR[$key]})" ] && valOf[service]=$key
		[ -n "$(echo ${valOf[subject]} | grep -i -E ${serviceTR[$key]})" ] && valOf[service]=$key && break
		# We trust on subject more than in the chosen category. Hope that improves one day.
	done
	logIt "NOTE :: ${valOf[category]} > ${valOf[subject]} Defined as service ${valOf[service]}."

	#link="https://arcosdorados.cloud.invgate.net/requests/show/index/id/${valOf[ticketID]}"

	plus1=false
	for key in "${printOrder[@]}"; do
		$plus1 && echo -n ";" >> $dstCSV || plus1=true
		echo -n ${valOf[$key]} >> $dstCSV
	done; echo >> $dstCSV

	val=${valOf[group]}
	[ -z "${ticketsPerGroup[$val]}" ] && ticketsPerGroup[$val]=1 || ((ticketsPerGroup[$val]++))

	val=${valOf[service]}
	[ -z "${ticketsPerService[$val]}" ] && ticketsPerService[$val]=1 || ((ticketsPerService[$val]++))
	[ -z "${translateService[$val]}" ] && translateService[$val]=$val

#echo "DEBUG :: L=[$L]"
	val=${valOf[client]}
#echo "DEBUG :: valOf[client]=[${valOf[client]}] :: ticketsPerClient[$val]=[${ticketsPerClient[$val]}]"
	[ -z "${ticketsPerClient[$val]}" ] && ticketsPerClient[$val]=1 || ((ticketsPerClient[$val]++))
	[ -z "${clientTickets[$val]}" ] && clientTickets[$val]= || clientTickets[$val]+="\n"
	clientTickets[$val]+="${valOf[ticketID]}\t\t${valOf[group]} / ${valOf[service]} / $(echo ${valOf[subject]} | sed 's/.*| //')"

	((regCount++))
	percent=$(echo "($regCount*100)/$origCount" | bc)
	msg="Parsed lines: ${percent}%"; [ $percent -lt 100 ] && msg+="..." || msg+="  "
	[ $debugLevel -gt 0 ] && echo -en "\rINFO :: $msg" || ( [[ "$regCount" =~ "0" ]] && logIt "NOTE :: $msg" )
done; echo; ((--regCount)) # <- Remove header count
logIt "INFO :: Generated file: $dstCSV."

for key in "${!ticketsPerService[@]}"; do
	#[ ${ticketsPerService[$key]} -lt 2 ] && continue
	logIt "${ticketsPerService[$key]}\t${translateService[$key]}"
done | sort -rn > $tmpCSV

#now=$(date +%s)
roundUp="$(echo "($(head -1 $tmpCSV | sed 's/[^0-9]//g')/10) + 2" | bc)0"
title="Chamados abertos, $(date -d"$(stat $srcFile | grep Modify | sed 's/Modify: //')" '+%d/%m/%Y %H:%M')"
gnuplot -e " \
	set terminal png; set terminal png size 400,600; set bmargin 8; set lmargin 5; set size 0.95,0.95; \
	set label 1 '$title' at graph -0.1, 0.35 centre rotate by 90; \
	set style fill solid 0.75; set boxwidth 0.5; unset ytics; \
	set yrange [0:$roundUp]; set grid y; set y2tics rotate by 90; set xtics rotate by 90 offset 0,-7; \
	set datafile separator '\t'; plot '$tmpCSV' using 0:1:0:xtic(2) notitle with boxes lc variable \
" > ${dstPNG} && convert -rotate 90 ${dstPNG} ${dstPNG}.tmp.png && mv ${dstPNG}.tmp.png ${dstPNG}
logIt "INFO :: Generated file: $dstPNG."

logIt "\nINFO :: Valid tickets parsed: $regCount"

logIt "\nTop Service offensor list:"
head -5 $tmpCSV

logIt "\nTop Group offensor list:"
for group in "${!ticketsPerGroup[@]}"; do
	[ ${ticketsPerGroup[$group]} -lt 2 ] && continue
	logIt "${ticketsPerGroup[$group]}\t$group"
done | sort -rn | head -3

logIt "\nClients with 2+ pending tickets:"
i=0; for client in "${!ticketsPerClient[@]}"; do
	[ ${ticketsPerClient[$client]} -lt 2 ] && continue
	[ $i -eq 0 ] && logIt "QTD\tSTORE\tTICKETS" || echo

	logIt "${ticketsPerClient[$client]}\t$client"
	for line in $(echo -e ${clientTickets[$client]}); do
		logIt "\t\t$line"
	done
	((i++)); [ $i -gt 9 ] && break
done; [ $i -eq 0 ] && logIt "(no registries found)" || echo

exit

# Sort to list by age (recent and ancient)
head -1 $dstCSV > $tmpCSV
sed -e '1d' $dstCSV | sort >> $tmpCSV
fStr='\t%-5s\t%s\t%s\t%-7s\t%-11s\t%-20s\t%-9s\t%s\\n'

res=
regCount=0
for L in $(tac $tmpCSV); do
	[ $regCount -gt 4 ] && break

	agent=$(echo $L | cut -d';' -f7)
	[ "${#agent}" -gt 4 ] && continue

	ticketMoment=$(echo $L | cut -d';' -f1)
	age=$(echo "( $(date +%s) - $(date -d "$ticketMoment" +%s) ) / (24*3600)" | bc)
	[ $age -gt 1 ] && break

	ticketID=$(echo $L | cut -d';' -f3)
	client=$(echo $L | cut -d';' -f4)
	service=$(echo $L | cut -d';' -f6)
	priority=$(echo $L | cut -d';' -f8)
	status=$(echo $L | cut -d';' -f9)
	group=$(echo $L | cut -d';' -f11)

	[ "${#agent}" -lt 3 ] && agent=
	ticketMoment=$(echo $ticketMoment | sed 's/[0-9]\{4\}-\([01][0-9]\)-\([0-9]\{2\}\).*/\2\/\1/')
	res+=$(printf $fStr "$ticketMoment" "$ticketID" "$client" "$priority" "${group:--}" "${service:--}" "$status" "${agent:--}")
	((regCount++))
done

if   [ $regCount -eq 0 ]; then echo -e "No recent (<24h) tickets found."
else
	[ $regCount -eq 1 ] && echo -e "Most recent (<24h) ticket:" || echo -e "$regCount most recent (<24h) tickets:"
	res="$(printf $fStr "DATE" "TICKET" "CLI" "PRIO" "GROUP" "SERVICE" "STATUS" "AGENT")$res"
	echo -e $res
fi

res=
regCount=0
for L in $(cat $tmpCSV | grep ^2019); do
	[ $regCount -gt 9 ] && break

	ticketMoment=$(echo $L | cut -d';' -f1)
	age=$(echo "( $(date +%s) - $(date -d "$ticketMoment" +%s) ) / (24*3600)" | bc)
	[ $age -lt 10 ] && break

	ticketID=$(echo $L | cut -d';' -f3)
	client=$(echo $L | cut -d';' -f4)
	service=$(echo $L | cut -d';' -f6)
	agent=$(echo $L | cut -d';' -f7)
	priority=$(echo $L | cut -d';' -f8)
	status=$(echo $L | cut -d';' -f9)
	group=$(echo $L | cut -d';' -f11)

	[ "${#agent}" -lt 3 ] && agent=
	ticketMoment=$(echo $ticketMoment | sed 's/[0-9]\{4\}-\([01][0-9]\)-\([0-9]\{2\}\).*/\2\/\1/')
	res+=$(printf $fStr "$ticketMoment" "$ticketID" "$client" "$priority" "${group:--}" "${service:--}" "$status" "${agent:--}")
	((regCount++))
done

if   [ $regCount -eq 0 ]; then echo -e "No older (>9d) tickets found."
else
	[ $regCount -eq 1 ] && echo -e "Most older (>9d) ticket:" || echo -e "$regCount most older (>9d) tickets:"
	res="$(printf $fStr "DATE" "TICKET" "CLI" "PRIO" "GROUP" "SERVICE" "STATUS" "AGENT")$res"
	echo -e $res
fi


# Format to open better in Excel
cat $tmpCSV | iconv -f UTF-8 -t ISO-8859-1 > $dstCSV

# Clean garbage
#rm -f $tmpCSV

