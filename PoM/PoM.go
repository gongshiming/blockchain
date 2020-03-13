package main

/*
PoM
设共有16^p个矿工
计算所有公钥对应的minimum，比较得出最小的minimum，若minimum(16进制)前p-1位不是0则对应的矿工挖矿成功，否则本轮共识区块由空区块代替。

*/

import (
	"crypto/elliptic"
	"crypto/ecdsa"
	"crypto/rand"
	"fmt"
	"bytes"
	"time"
	"encoding/binary"
	"os"
	"crypto/sha256"
)

var sks [1<<11] ecdsa.PrivateKey
var pks [1<<11] []uint8

type block struct {
	version   string
	perHash   []byte
	merkle    []byte
	timeStamp int64
	publicKey []byte
	h         []byte
}

func Int64ToBytes(i int64) []byte {
	var buf = make([]byte, 8)
	binary.BigEndian.PutUint64(buf, uint64(i))
	return buf
}

//对[]byte数据进行sha256，返回结果
func _sha256(b []byte) ([]byte) {
	s_ob := sha256.New()
	s_ob.Write(b)
	return s_ob.Sum(nil)
}

//BytesCombine 多个[]byte数组合并成一个[]byte
func BytesCombine(pBytes ...[]byte) ([]byte) {
	len := len(pBytes)
	s := make([][]byte, len)
	for index := 0; index < len; index++ {
		s[index] = pBytes[index]
	}
	sep := []byte("")
	return bytes.Join(s, sep)
}

//生成随机32位[]byte，即256位二进制，用于代替merkle
func Getcryto_randombytes() (merkle []byte) {
	merkle = make([]byte, 32)
	_, err := rand.Read(merkle)
	if err != nil {
		fmt.Println(err.Error())
	}
	return
}

//对一个区块进行sha256
func getBlockHash(block block) (blockHash []byte) {
	blockHash = _sha256(BytesCombine(
		[]byte(block.version),
		block.perHash,
		block.merkle,
		Int64ToBytes(block.timeStamp),
		block.publicKey,
		block.h))

	return
}

var blocks [][]block

//生成创世区块
func initFirstBlock() {
	//设置block[0]内容
	block1 := block{
		version:   "1.0",
		perHash:   _sha256([]byte("本兮")),
		merkle:    _sha256([]byte("本兮")),
		timeStamp: time.Now().Unix(),
		publicKey: pks[0],
		h:         _sha256(BytesCombine(_sha256([]byte("本兮")), pks[0]))}
	var block1s []block
	block1s = append(block1s, block1)
	blocks = append(blocks, block1s)
}

//生成区块
func initBlock(pk []byte, h []byte) (block1 block) {
	block1 = block{
		version:   "1.0",
		perHash:   getBlockHash(blocks[len(blocks)-1][0]),
		merkle:    Getcryto_randombytes(),
		timeStamp: time.Now().Unix(),
		publicKey: pk,
		h:         h}
	return
}

//生成一对私钥和公钥
func newKeyPair() (ecdsa.PrivateKey, []byte) {

	//生成椭圆曲线,  secp256r1 曲线。    比特币当中的曲线是secp256k1
	curve := elliptic.P256()

	private, err := ecdsa.GenerateKey(curve, rand.Reader)

	if err != nil {

		fmt.Println("error")
	}
	pubkey := append(private.PublicKey.X.Bytes(), private.PublicKey.Y.Bytes()...)

	return *private, pubkey

}

//生成一组私钥和公钥
func newKeyPairs() () {
	for i := 0; i < len(sks); i++ {
		sks[i], pks[i] = newKeyPair()
		for len(pks[i]) != 64 {
			sks[i], pks[i] = newKeyPair()
		}
		fmt.Printf("%d%T,%x\n", i, sks[i].D.Bytes(), sks[i].D.Bytes())
		fmt.Printf("%d%T,%x\n", i, pks[i], pks[i])
		for j := 0; j < i; j++ {
			bytes.Compare(sks[i].D.Bytes(), sks[j].D.Bytes())
			if bytes.Compare(sks[i].D.Bytes(), sks[j].D.Bytes()) == 0 {
				fmt.Println(i, "随机生成的私钥出现碰撞***************************************************")
			}
			break
		}
		fmt.Println("--------------------------------------------------------------------------------------------")
	}
}

//比较两个[]beyte的大小,b1==b2时返回0，b1<b2是为-1，b1>b2时为1，b1为已知最小h，b2为新的h
var t int

func bytes_min(b1 []byte, b2 []byte) (isEqual int) {
	//在下面的调用中，b1有表达过每个区块的publicKey，而空区块没有publicKey，需要加个判断
	isEqual = -1
	if len(b1) == 0 {
		isEqual = 2
		return
	}
	if len(b1) != len(b2) {
		t++
		fmt.Printf("测试出错第%d次。\nb1:%x\nb2:%x\n", t, b1, b2)
		os.Exit(3)
	}
	for i := 0; i < len(b1); i++ {
		if b1[i] < b2[i] {
			return
		} else if b1[i] > b2[i] {
			isEqual = 1
			return
		}
	}
	if b1[len(b1)-1] == b2[len(b2)-1] {
		isEqual = 0
	}
	return
}

//判断h_min的前p-1位是不是都是0，若是返回真，不是返回假。
func h_minIsOK(h_min []byte) (isOK bool) {
	isOK = true
	for i := 0; i < 1; i++ {
		if h_min[i] != 0 {
			isOK = false
		}
	}
	return
}

//比较所有pk对应h的大小，返回最小的几个及他们的h
func bytes_mins(perHash []byte) (hmin_pks [][]byte, h_min []byte) {
	h_min = _sha256(BytesCombine(perHash, pks[0]))
	hmin_pks = append(hmin_pks, pks[0])
	for i := 1; i < len(pks); i++ {
		h := _sha256(BytesCombine(perHash, pks[i]))
		isEqual := bytes_min(h_min, h)
		if isEqual == 0 {
			hmin_pks = append(hmin_pks, pks[i])
		} else if isEqual == 1 {
			h_min = h
			hmin_pks = hmin_pks[:1]
			hmin_pks[0] = pks[i]
		}
	}
	return
}

//生成一个空区块
var emptyBlockNumber int
func initEmptyBlock() (block1 block) {
	emptyBlockNumber++
	block1 = block{
		version:   "1.0",
		perHash:   _sha256([]byte("本兮")),
		merkle:    nil,
		timeStamp: time.Now().Unix(),
		publicKey: nil,
		h:         nil}
	time.Sleep(time.Duration(3)*time.Millisecond)
	return
}

//所有的全节点开始挖矿，区块链增长1个高度，如果出现临时分叉则终止程序
func addBlock2() {
	fmt.Printf("目前区块高度：%d\n", len(blocks))
	hmin_pks, h_min := bytes_mins(getBlockHash(blocks[len(blocks)-1][0]))
	if h_minIsOK(h_min) {	//h_min符合要求，生成正常区块
		if len(hmin_pks) == 1 {
			block1 := initBlock(hmin_pks[0], h_min)
			var block1s []block
			block1s = append(block1s, block1)
			blocks = append(blocks, block1s)
			fmt_block(block1)
		} else {
			fmt.Printf("出现临时分叉。\n")
			os.Exit(1)
		}
	} else {	//h_min不符合要求，生成空区块
		block1 := initEmptyBlock()
		var block1s []block
		block1s = append(block1s, block1)
		blocks = append(blocks, block1s)
		fmt_block(block1)
	}


}

//所有的全节点开始挖矿，区块链增长1个高度，如果出现临时分叉则打印出分叉的详细信息，只考虑上一个高度没有发生临时分叉
func addBlock1() {

	hmin_pks, h_min := bytes_mins(getBlockHash(blocks[len(blocks)-1][0]))
	if len(hmin_pks) > 1 { //区块链在此高度临时分叉
		fmt.Printf("区块链在%d高度临时分叉，分叉为%d条链，h = %x. \n",
			len(blocks), len(hmin_pks), h_min)
		for i := 0; i < len(hmin_pks); i++ {
			block1 := block{
				version:   "1.0",
				perHash:   getBlockHash(blocks[len(blocks)-1][0]),
				merkle:    Getcryto_randombytes(),
				timeStamp: time.Now().Unix(),
				publicKey: hmin_pks[i],
				h:         h_min}
			blocks[len(blocks)][i] = block1
			fmt.Printf("第%d条链的publicKey = %x\n", i+1, hmin_pks[i])
			fmt_block(block1)
		}
		fmt.Printf("---------------------------------------------------------------------------------------------")
	}

}

//所有的全节点开始挖矿，区块链增长1个高度，如果出现临时分叉则打印出分叉的详细信息，
// 考虑上一个高度可能发生临时分叉，如果临时分叉则需要判断多个分支的新生区块的h，留最小的。
// 不考虑分支上再发生临时分叉。
func addBlock() {
	fmt.Printf("目前区块高度：%d\n", len(blocks))
	if len(blocks) > 10000 {
		fmt.Printf("区块链高度达到10000，程序终止。\n")
		os.Exit(1)
	}
	for i := 0; i < len(blocks[len(blocks)-1]); i++ {
		hmin_pks, h_min := bytes_mins(getBlockHash(blocks[len(blocks)-1][0]))
		if len(hmin_pks) > 1 { //区块链在此高度临时分叉
			if i > 0 {
				fmt.Printf("分支上又出现了分叉，程序终止。\n")
				os.Exit(1)
			}
			fmt.Printf("区块链在%d高度临时分叉，分叉为%d条链，h = %x. \n",
				len(blocks), len(hmin_pks), h_min)
			for i := 0; i < len(hmin_pks); i++ {
				block1 := initBlock(hmin_pks[i], h_min)
				var block1s []block
				block1s = append(block1s, block1)
				blocks = append(blocks, block1s)
				fmt.Printf("第%d条链的publicKey = %x\n", i+1, hmin_pks[i])
				fmt_block(block1)
			}
			fmt.Printf("---------------------------------------------------------------------------------------------")
		} else {

		}
	}
}

//打印一个block信息
func fmt_block(block block) () {
	fmt.Printf("区块信息：version:%s, \n\tperHash:%x, \n\tmerkle:%x, \n\ttimeStamp:%d, \n\tpublicKey:%x, \n\th:%x\n",
		block.version, block.perHash, block.merkle, block.timeStamp, block.publicKey, block.h)
}

func main() {
	newKeyPairs()
	for i := 0; i < len(pks); i++ {
		if len(pks[i]) != 64 {
			fmt.Printf("第%d个公钥的长度不是64，是%d，其公钥是：%x\n", i, len(pks[i]), pks[i])
			os.Exit(3)
		}
	}

	initFirstBlock()
	for i := 0; i < 9999; i++ {
		addBlock2()
	}
	var statistics [len(pks)]int
	for i := 0; i < len(blocks); i++ {
		for j := 0; j < len(pks); j++ {
			isEqual := bytes_min(blocks[i][0].publicKey, pks[j])
			if isEqual == 0 {
				statistics[j] ++
			}
		}
	}
	fmt.Println("各个矿工挖到的区块数量：", statistics)

	num := len(statistics)
	for i := 0; i < num; i++ {
		for j := i + 1; j < num; j++ {
			if statistics[i] < statistics[j] {
				tmp := statistics[i]
				statistics[i] = statistics[j]
				statistics[j] = tmp
			}
		}
	}
	var n int
	for i := 0 ; i < num; i++ {
		n = n + statistics[i]
	}
	fmt.Printf("n:%d\nn+emptyBlockNumber = %d\n", n, n+emptyBlockNumber)
	fmt.Println("对各个矿工挖到的区块数量从大到小排序后：", statistics)
	fmt.Printf("空区块的个数为：%d\n", emptyBlockNumber)
}
