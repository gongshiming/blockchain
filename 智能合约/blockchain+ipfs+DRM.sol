pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract releaseInBatchesV2_0 {
    //管理员
    address public administrator;
    constructor() public{
        administrator = msg.sender;
    }
    //密钥保护中心
    address public keyProtectionCenter;
    //创作者代表
    mapping(address => bool) public creatorDelegateApplication;
    address[] creatorDelegates;
    //创作者列表
    struct creatorList {
        address[] creator_address;
        uint256[] creator_proportion;
    }
    //消费者address, publicKey
   struct buyer {
       address[] buyer_address;
       string[] key;
    //   string[] publicKey;
   }
    //歌曲信息
    struct song {
        string ipfs;
        string songDescribe;
        creatorList creators;
        string right;
        uint256 price;//单位finney，即人民币-元（兑换比例1eth = 1000元人民币）
        buyer buyers;//购买该歌曲的消费者
        //卖出该歌曲密钥保护中心得到的收益，单位1/100finney，即人民币-分
        uint256 keyProfits;//单位1/100finney，即人民币-分
        uint256 adminProfits;
    }
    // 歌曲的ipfs => 歌曲详情 
    mapping(string => song) songContent;
    // 专辑信息
    struct album {
        bool canBuy;
        string[] songIpfsList;
        string albumDescribe;
        creatorList creators;
        string right;
        uint256 price;//单位finney，即人民币-元（兑换比例1eth = 1000元人民币）
        buyer buyers;//购买该专辑的消费者
        //卖出该专辑密钥保护中心得到的收益，单位1/100finney，即人民币-分
        uint256 keyProfits;
        uint256 adminProfits;
    }
    // 专辑的ipfs => 专辑信息
    mapping(string => album) albumContent;
    // 专辑的ipfs => 专辑歌曲列表
    mapping(string => song[]) albumSongList;
    // 创作者的专辑列表
    mapping(address => string[]) creatorDelegateAlbumList;
    string[] allAlbum;
    
    //-----------------------------行为---------------------------
    //智能合约行为
    //智能合约判断调用智能合约的创作者代表是否是某专辑的创作者代表
    function checkCreatorDelegateAlbum(address _creatorDelegate, string _ipfs)
    view public returns (bool isOK_) {
        // string[] storage creatorDelegateAlbums;
        // creatorDelegateAlbums = creatorDelegateAlbumList[_creatorDelegate];
        for(uint256 i = 0; i < creatorDelegateAlbumList[_creatorDelegate].length; i++) {
            if(keccak256(creatorDelegateAlbumList[_creatorDelegate][i]) == keccak256(_ipfs)) {
                isOK_ = true;
                return;
            }
        }
        isOK_ = false;
        return;
    }
    //智能合约判断是否有某个专辑
    function checkAlbum(string _ipfs) view public returns(bool isOK_){
        for(uint256 i = 0; i < allAlbum.length; i++) {
            if(keccak256(allAlbum[i]) == keccak256(_ipfs)) {
                isOK_ = true;
                return;
            }
        }
        isOK_ = false;
    }
    //智能合约判断某专辑中是否已存在某首歌
    function checkAlbumHaveSong(string _ipfs_album, string _ipfs_song)
    view public returns(bool isOK_, uint256 index_) {
        if(albumSongList[_ipfs_album].length != 0) {
            for(uint256 i = 0; i < albumSongList[_ipfs_album].length; i++) {
                if(keccak256(_ipfs_song) == keccak256(albumSongList[_ipfs_album][i].ipfs)) {
                    isOK_ = true;
                    index_ = i;
                    return;
                }
            }
        }
        isOK_ = false;
        index_ = 0;
    }
    //智能合约判断买了某张专辑内的某首歌是否有某个购买者的地址
    function checkSongHaveBuyer
    (string _ipfs_album, string _ipfs_song, address _buyer_address)
    view public returns(bool isOK_, uint256 index1_, uint256 index2_) {
        isOK = false;
        index1_ = 0;
        index2_ = 0;
        bool isOK;
        (isOK, index1_) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(isOK);
        for(uint256 i = 0; i < albumSongList[_ipfs_album][index1_].buyers.buyer_address.length; i++) {
            if(_buyer_address == albumSongList[_ipfs_album][index1_].buyers.buyer_address[i]) {
                index2_ = i;
                isOK_ = true;
                return;
            }
        }
        isOK_ = false;
        return;
    }
    //管理员行为
    //管理员添加创作者代表
    function addCreator(address _creatorDelegate) public {
        require(msg.sender == administrator);
        creatorDelegateApplication[_creatorDelegate] = true;
        creatorDelegates.push(_creatorDelegate);
    }
    //管理员设置密钥保护中心
    function setKeyProtectionCenter(address _keyProtectionCenter) public {
        require(msg.sender == administrator);
        keyProtectionCenter = _keyProtectionCenter;
    }
    function setAdminProfits(string _ipfs_album, uint256 _adminProfits) public {
        require(msg.sender == administrator);
        albumContent[_ipfs_album].adminProfits = _adminProfits;
    }
    //创作者代表行为
    //创作者代表查看是否已具有发布专辑的资格
    function checkDelegateCreator(address _creatorDelegate) view public returns (bool isOK_){
        isOK_ = creatorDelegateApplication[_creatorDelegate];
    }
    //创作者代表添加一个专辑的IPFS及设置专辑描述及密钥保护中心和平台的收益
    function setNewAlbum
    (string _ipfs, string _albumDescribe) public {
        require(creatorDelegateApplication[msg.sender]);
        creatorDelegateAlbumList[msg.sender].push(_ipfs);
        allAlbum.push(_ipfs);
        albumContent[_ipfs].albumDescribe = _albumDescribe;
        // albumContent[_ipfs].keyProfits = _keyProfits;
        // albumContent[_ipfs].adminProfits = _adminProfits;
    }
    
    // function completeAlbum(string _ipfs_album_new, string _ipfs_album_old) public{
    //     require(creatorDelegateApplication[msg.sender]);
    //     require(checkCreatorDelegateAlbum(msg.sender, _ipfs_album_old));
    //     creatorDelegateAlbumList[msg.sender].push(_ipfs_album_new);
    //     allAlbum.push(_ipfs_album_new);
    //     albumContent[_ipfs_album_new] = albumContent[_ipfs_album_old];
        
    // }
    //创作者代表设置某专辑是否可以购买
    function setAlbumCanBuy(string _ipfs_album, bool _canBuy) public {
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs_album));
        albumContent[_ipfs_album].canBuy = _canBuy;
    }
    //创作者代表为一个专辑添加创作者
    function addCreatorsForAlbum(string _ipfs, address _creator, uint256 _proportion) public {
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs));
        uint256 alreadyProportion;
        
        for (uint256 i = 0; i < albumContent[_ipfs].creators.creator_address.length; i++) {
            alreadyProportion += albumContent[_ipfs].creators.creator_proportion[i];
        }
        if((alreadyProportion + _proportion) > 100) {
            revert();
        }
        albumContent[_ipfs].creators.creator_address.push(_creator);
        albumContent[_ipfs].creators.creator_proportion.push(_proportion);
    }
    //创作者代表为一个专辑设置价格
    function setPriceForAlbum(string _ipfs, string _right, uint256 _price) public {
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs));
        albumContent[_ipfs].right = _right;
        albumContent[_ipfs].price = _price;
    }
    //创作者代表为某专辑添加歌曲，包括IPFS和描述
    function addSongToAlbum
    (string _ipfs_album, string _ipfs_song, string _songDescribe, uint256 _keyProfits, uint256 _adminProfits) public {
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs_album));
        bool isOK;
        uint256 index;
        (isOK, index) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(!isOK);
        song memory song1;
        song1.ipfs = _ipfs_song;
        song1.songDescribe = _songDescribe;
        song1.keyProfits = _keyProfits;
        song1.adminProfits = _adminProfits;
        song1.buyers.buyer_address = albumContent[_ipfs_album].buyers.buyer_address;
        albumSongList[_ipfs_album].push(song1);
        
        uint256 len1 = albumSongList[_ipfs_album].length;
        uint256 len2 = albumSongList[_ipfs_album][len1-1].buyers.buyer_address.length;
        for(uint256 i = 0; i < len2; i++) {
            albumSongList[_ipfs_album][len1-1].buyers.key.push("");
        }
    }
    //创作者代表为某专辑中的某歌曲添加创作者及分成
    function addCreatorsForSong
    (string _ipfs_album, string _ipfs_song, address _creator, uint256 _proportion)
    public{
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs_album));
        bool isOK;
        uint256 index;
        (isOK, index) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(isOK);
        uint256 alreadyProportion1;
        for(uint256 j = 0; j < albumSongList[_ipfs_album][index].creators.creator_proportion.length; j++) {
            alreadyProportion1 += albumSongList[_ipfs_album][index].creators.creator_proportion[j];
        }
        require((alreadyProportion1 + _proportion) <= 100);
        albumSongList[_ipfs_album][index].creators.creator_address.push(_creator);
        albumSongList[_ipfs_album][index].creators.creator_proportion.push(_proportion);
    }
    //创作者代理为某专辑内的某首歌曲设置权限描述及价格
    function setRightAndPriceForSong
    (string _ipfs_album, string _ipfs_song, string _right, uint256 _price)
    public{
        require(creatorDelegateApplication[msg.sender]);
        require(checkCreatorDelegateAlbum(msg.sender, _ipfs_album));
        bool isOK;
        uint256 index;
        (isOK, index) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(isOK);
        albumSongList[_ipfs_album][index].right = _right;
        albumSongList[_ipfs_album][index].price = _price;
    }
    
    //消费者行为
    //获取某专辑的信息 (创作者和消费者或其他人都可以查看)
    function getInformationOfAlbum(string _ipfs) view public returns 
    (string ipfs_, string albumDescribe_, string right_, uint256 price_, 
    address[] creatorAddress_, uint256[] proportion_) {
        require(checkAlbum(_ipfs));
        ipfs_ = _ipfs;
        albumDescribe_ = albumContent[_ipfs].albumDescribe;
        right_ = albumContent[_ipfs].right;
        price_ = albumContent[_ipfs].price;
        creatorAddress_ = albumContent[_ipfs].creators.creator_address;
        proportion_ = albumContent[_ipfs].creators.creator_proportion;
    }
    //获取某专辑内某歌曲的信息(创作者和消费者或其他人都可以查看)
    function getInformationOfContent(string _ipfs_album, string _ipfs_song)
    view public returns 
    (string ipfs_, string songDescribe_, uint256 countOfSongs_, address[] creatorAddress_, 
    uint256[] proportion_, string right_, uint256 price_) {
        bool isOK;
        uint256 index;
        (isOK, index) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(isOK);
        ipfs_ = albumSongList[_ipfs_album][index].ipfs;
        songDescribe_ = albumSongList[_ipfs_album][index].songDescribe;
        countOfSongs_ =  albumSongList[_ipfs_album].length;
        creatorAddress_ = albumSongList[_ipfs_album][index].creators.creator_address;
        proportion_ = albumSongList[_ipfs_album][index].creators.creator_proportion;
        right_ = albumSongList[_ipfs_album][index].right;
        price_ = albumSongList[_ipfs_album][index].price;
    }
    //购买某张专辑
    function buyAlbum(string _ipfs_album) payable public {
        require(albumContent[_ipfs_album].canBuy && 
        msg.value >= (albumContent[_ipfs_album].price*1e15 
        + albumContent[_ipfs_album].keyProfits*1e13
        + albumContent[_ipfs_album].adminProfits*1e13));
        for(uint256 i = 0; i < albumContent[_ipfs_album].creators.creator_address.length; i++) {
            albumContent[_ipfs_album].creators.creator_address[i].transfer
            (albumContent[_ipfs_album].price
            *albumContent[_ipfs_album].creators.creator_proportion[i]*1e15/100);
        }
        keyProtectionCenter.transfer(albumContent[_ipfs_album].keyProfits*1e13);
        administrator.transfer(albumContent[_ipfs_album].adminProfits*1e13);
        msg.sender.transfer
        (msg.value - albumContent[_ipfs_album].price*1e15 
        - albumContent[_ipfs_album].keyProfits*1e13
        - albumContent[_ipfs_album].adminProfits*1e13);
        albumContent[_ipfs_album].buyers.buyer_address.push(msg.sender);
        for(uint256 j = 0; j < albumSongList[_ipfs_album].length; j++) {
            albumSongList[_ipfs_album][j].buyers.buyer_address.push(msg.sender);
            albumSongList[_ipfs_album][j].buyers.key.push("");
        }
    }
    //购买某张专辑的某首歌曲
    function buySong(string _ipfs_album, string _ipfs_song) 
    payable public {
        bool isOK;
        uint256 index;
        (isOK, index) = checkAlbumHaveSong(_ipfs_album, _ipfs_song);
        require(!isOK);
        require(msg.value >= (albumSongList[_ipfs_album][index].price*1e15
        + albumSongList[_ipfs_album][index].keyProfits*1e13 
        + albumSongList[_ipfs_album][index].adminProfits*1e13));
        for(uint256 i = 0; i < albumSongList[_ipfs_album][index].creators.creator_address.length; i++) {
            albumSongList[_ipfs_album][index].creators.creator_address[i].transfer
            (albumSongList[_ipfs_album][index].price
            *albumSongList[_ipfs_album][index].creators.creator_proportion[i]*1e15/100);
        }
        keyProtectionCenter.transfer(albumSongList[_ipfs_album][index].keyProfits*1e13);
        administrator.transfer(albumSongList[_ipfs_album][index].adminProfits*1e13);
        msg.sender.transfer
        (msg.value - albumSongList[_ipfs_album][index].price*1e15
        - albumSongList[_ipfs_album][index].keyProfits*1e13
        - albumSongList[_ipfs_album][index].adminProfits*1e13);
        albumSongList[_ipfs_album][index].buyers.buyer_address.push(msg.sender);
        albumSongList[_ipfs_album][index].buyers.key.push("");
    }
    //消费者（任何人）查看某专辑是否可以购买
    function getCanBuyAlbum(string _ipfs_album) view public returns (bool canBuy_) {
        canBuy_ = albumContent[_ipfs_album].canBuy;
    }
    //消费者获取许可证
    function getLicence(string _ipfs_album, string _ipfs_song) view public returns
    (string ipfs_album_, string ipfs_song_, address buyer_address_, string right_, string key_) {
        bool isOK;
        uint256 index1;
        uint256 index2;
        (isOK, index1, index2) = checkSongHaveBuyer(_ipfs_album, _ipfs_song, msg.sender);
        require(isOK);
        ipfs_album_ = _ipfs_album;
        ipfs_song_ = _ipfs_song;
        buyer_address_ = msg.sender;
        right_ = albumSongList[_ipfs_album][index1].right;
        key_ = albumSongList[_ipfs_album][index1].buyers.key[index2];
    }
    //密钥保护中心行为
    //设置某专辑内的某歌曲的购买者的密钥（已用购买者公钥加密）
    function setKeyProfits(string _ipfs_album, uint256 _keyProfits) public {
        require(msg.sender == keyProtectionCenter);
        albumContent[_ipfs_album].keyProfits = _keyProfits;
    }
    
    function setSongBuyerKey
    (string _ipfs_album, string _ipfs_song, address _buyer_address, string _key)
    public {
        require(msg.sender == keyProtectionCenter);
        bool isOK;
        uint256 index1;
        uint256 index2;
        (isOK, index1, index2) = checkSongHaveBuyer(_ipfs_album, _ipfs_song, _buyer_address);
        require(isOK);
        albumSongList[_ipfs_album][index1].buyers.key[index2] = _key;
    }
    
    
}