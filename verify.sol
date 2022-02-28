//address: 0xa492cfc4221dc0bb3edac48e863e6040ef177905
/*
input: 1 2 3
h[0]: 18444058245820418255538785847032978363886102372504864086197416499869253008979

h1[0]: 20698283370085552773400605255890225648253150251298138717849956593834826648335

proof: [["0x2d4b19c0a314cd5e6d9c0267e1a8f296636c461bf77574394a3701d047bf5dab","0x0915d28122be27dd0a3f572ce817c4af4b8a2efd16d3e13d5a07d04129c4b4d5"],["0x107e3664c3288e726e0025716b4ba8aaea08158a71ba729e3635c7255bbd782f","0x2584826d0c30720ff09ecbc3ef9e187b8d7901e50e43e9155cd312840d0c3053"],[["0x2bb744b0dacc31ce8512a5cc87b373cb4b7df2edd3eb1a0b7000d241567df0df","0x1eea0bf8ae2609b5126c9b4be055f44b83b800d39a323d5aa3f4f9f1c12c609c"],["0x090fad1af6224739678bed5617926ae79da10877644ac569471a768b47245646","0x0ebba86e6d7c3e1f0777294e80c2ab3a7f167c41cc34251bf3e03cb9f5a0d61e"]],["0x2f2d745f9915863052840e624f94558e904b9bbe4f72ce68a84f512314e8ca19","0x08c68a7b67c1a9371cb99818197083e187a1994ba194567b1c281fb2015fdd33"],["0x009a61e259d7e5754faa27486e17ec56664e38bf890eb9123fdd584d236a2e6a","0x02930c2d98bf5f78e2349af38591e76964d3958113e4bee1ca0bec433e23ce87"],["0x2d6476e26659984a667148b8466e038505b420a8c677f3f6bdaa6289d40106fc","0x29b481ea34e8e178d1d68cc702951474ed74d1ceeba32184dd2633a342e09bf3"],["0x2b2f056eacc7aa0dabce99772881b7cdeef9227bdb6e1d0ba61cc4b9acea8809","0x1cb871d9e37af908b66b1f59430e804580b76ae3b7b5f4443df9faaa9b86ef9c"],["0x2d164982d8400384c4a7e58e6c20bf2293efabf373fd07098cda90bbd32c63c5","0x1cb35e74b4bfa71621088b9fbf32d4ab067e9cb45e7b6527fcf2b6b8b05d95d0"]]

input: ["0x2dc2d02fd994af7a6c28b2a79c2c647a83e10f57aa061688f5a8445c89efcb0f"]
*/
// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point a;
        Pairing.G1Point b;
        Pairing.G2Point c;
        Pairing.G2Point gamma;
        Pairing.G1Point gamma_beta_1;
        Pairing.G2Point gamma_beta_2;
        Pairing.G2Point z;
        Pairing.G1Point[] ic;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G1Point a_p;
        Pairing.G2Point b;
        Pairing.G1Point b_p;
        Pairing.G1Point c;
        Pairing.G1Point c_p;
        Pairing.G1Point h;
        Pairing.G1Point k;
    }
    //============================================
    struct metaData{
        uint256 ID;
        uint256 m;
    }
    
    struct Pseudonyms {
        address adr;            //address of pseudonym
        uint256 pi;             //parameter
        uint256[] devices;      //devices list
    }
    
    uint cnt = 0;
    uint dv_cnt = 0;
    Pseudonyms[1000] pseu;
    metaData[10000] dv;
    
    function checkPar(uint[] memory inputVal) internal returns (bool){
        uint i;
        uint c = inputVal[0];
        for(i=0; i<=cnt; i++){
            if(c == pseu[i].pi)
                return false;
        }
        store(c);
        return true;
    }
      
    function store(uint p) private{
        pseu[cnt].adr = msg.sender;
        pseu[cnt].pi = p;
        cnt++;
    }
    
    function addDevices(uint256 m,uint256 id) public returns (bool){
        uint i;
        for(i=0;i<=cnt;i++){
            if(msg.sender == pseu[i].adr){
                pseu[i].devices.push(m);
                dv[dv_cnt].m = m;
                dv[dv_cnt].ID = id;
                dv_cnt++;
                return true;
            }
        }
        return false;
    }

    function checkPseu() private view returns (bool){
        uint i;
        for(i=0;i<=cnt;i++){
            if(msg.sender == pseu[i].adr) return true;
        }
        return false;
    }

    function removeDevices(uint256 m) public returns(bool){
        if(checkPseu()){
            uint i;
            uint j;
            for(i=0;i<cnt;i++){
                if(msg.sender == pseu[i].adr){
                    uint len = pseu[i].devices.length;
                     for(j=0;j<len;j++){
                         if(m == pseu[i].devices[j]){
                            delete(pseu[i].devices[j]);
                            pseu[i].devices[j] = pseu[i].devices[len-1];
                        }
                     }
                     for(j=0;j<dv_cnt;j++){
                         if(m == dv[j].m){
                             dv[j].m = 0;
                             dv[j].ID = 0;
                             dv[j]=dv[dv_cnt-1];
                             dv_cnt--;
                         }
                     }//end dv for
                     return true;
                }//end if
            }//end big for
        }
        return false;
    }
    
    metaData public qresult;

    function query(uint256 m) public returns (metaData memory){
        uint i;
        
        for(i=0;i<dv_cnt;i++){
            if(m == dv[i].m){
                qresult = dv[i];
                return qresult;
            }
        }
        qresult.m = 0; qresult.ID = 0;
        return qresult;
    }
    //============================================
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.a = Pairing.G2Point([uint256(0x0e952ca7cf32565ec05233cd530739e1e7ca929fc19311b852e4c10679224516), uint256(0x1f6706c293a11e98f7fe3288aec2cbf6ff7392d5eb1eb74cf9e94b2065e4c161)], [uint256(0x190b84da4c05fdc4ae16cca1367cc8aceaea3895216249413fb13265955e4443), uint256(0x042b0a88a6309dd8902d739579f1ce527842d75e3e02961c58220a93da843784)]);
        vk.b = Pairing.G1Point(uint256(0x186c6fb5e6ab0017808168af83dcfe4a945557a3e9903046854a50810ea80603), uint256(0x2c6f2081032255c09eba04d8bb6fbe93352abccba4b3924fe290a3fa75cbce03));
        vk.c = Pairing.G2Point([uint256(0x077108136d79cbee30e5cbed9e27e993486870ddd982c5e58f3736756a5a0351), uint256(0x11841ecbc9477bfe672917ff314c42223b63e5e5939febdf7300a634726b1891)], [uint256(0x0e9af023e0d4be4f02dcbef84a14a0df941a255bea1b74393e3f88524cf7853d), uint256(0x2a14514614d6e6a8cfc6b3ee042908249ce58befadddf5076795e4c409567941)]);
        vk.gamma = Pairing.G2Point([uint256(0x1689e6dfe511bbd3f465c683219cb66e888b312f9e450c59e90431192dccbffe), uint256(0x24f4d84d6faa770940b27611735f9581573d2a97be6261b3aa1d7eb8bb607cb2)], [uint256(0x15a63109b1658bb0aeb2cf51058001279889f7e98ed2dfac156a695185ce992a), uint256(0x27907c89000098eb59274b32be4c799715b64b3974dcef32fae391ba4c292231)]);
        vk.gamma_beta_1 = Pairing.G1Point(uint256(0x025e1aab4af057c1f1ec5b51073b00d0dec8b96aa53a590b108af7dd5615cb52), uint256(0x2231d2cd98f51303af826e89949323687a0c2294131f17ad6769fc3cc13ac66c));
        vk.gamma_beta_2 = Pairing.G2Point([uint256(0x1abaed28a7336b2366852ca7171bab3461bbe98aafeabfc0e770a595750a0e9e), uint256(0x2eacc7fbf11437e44ef11db6f5d77c855d3fe4de87491a0be4242bb9630e53c7)], [uint256(0x1382138a0c7b5173144e2ab766683f4802027ed9faf99acbb597d92e89f24cf0), uint256(0x2559962955ddc168e57d34bd3ec2bfb4b205dd31a6598f24201b5b69ba0a3d19)]);
        vk.z = Pairing.G2Point([uint256(0x27d6de9291f027da9bb5e72e7576360956b5e0398a1727606d2bd6b13ea1c15c), uint256(0x13b4b4f8e60d9f3a1c0add19c016e7c34608950e418b02fcf7339179ebc1b8cb)], [uint256(0x2d13e94365c4b03f93e6576e5078be06acbe087b619b07de29d2ee98da1198b3), uint256(0x08799c51f0e2213bc7f4fec8bc4308970f29a09e17d65fb6983ea87bfd23d303)]);
        vk.ic = new Pairing.G1Point[](2);
        vk.ic[0] = Pairing.G1Point(uint256(0x26d880ce4303adde015ade150da9397e652924a14cc5152eb35f294b2b98ebfc), uint256(0x1c8395baaaa53202aa4199ec23d1693779616bc4971c89d1109793665d65b0ec));
        vk.ic[1] = Pairing.G1Point(uint256(0x173d27742abe5eabc064cf25170da120a783f597a157a584d49b9a6611fad2c8), uint256(0x16a4cf0e4c979904aba206a4aa630f3f6a1a479fcb7c0f97c944529fd0154013));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.ic.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.ic[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.ic[0]);
        if (!Pairing.pairingProd2(proof.a, vk.a, Pairing.negate(proof.a_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.b, proof.b, Pairing.negate(proof.b_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.c, vk.c, Pairing.negate(proof.c_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.k, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.a, proof.c))), vk.gamma_beta_2,
            Pairing.negate(vk.gamma_beta_1), proof.b
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.a), proof.b,
                Pairing.negate(proof.h), vk.z,
                Pairing.negate(proof.c), Pairing.P2()
        )) return 5;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[1] memory input
        ) public returns (bool r) {
        uint[] memory inputValues = new uint[](1);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            if(checkPar(inputValues))
                return true;
            else
                return false;
        } else {
            return false;
        }
    }
}
