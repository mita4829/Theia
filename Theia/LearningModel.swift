//
//  LearningModel.swift
//  Theia
//
//  Created by Michael Tang on 2/26/18.
//  Copyright © 2018 Michael Tang. All rights reserved.
//

/*Learning model takes previous characters extracted from images and the user's input on the validity of the word, and it learns from its current mistakes, learning to adapt to different characters. */

import Foundation


var learnedSet:[String:[ [[UInt8]] ]] = [:]
var correctMatrices:[ [[UInt8]] ] = []

/*Takes an UInt8 matrix, and compares it with previous known characters classified from the user and returns the likely character*/
func classifyFromLearnedSet(matrix m:[[UInt8]]) -> (String, Double) {
    var highestMatch:Double = 0
    var highestMatchCharacter:String = ""
    var currentMatch:Double = 0

    for key in learnedSet {
        let learnedCharacterMatrixSet:[[[UInt8]]] = learnedSet[key.key]!
        for matrixCount in 0..<learnedCharacterMatrixSet.count {
            for row in 0..<CELL_SIZE {
                for col in 0..<CELL_SIZE {
                    if(m[row][col] == learnedCharacterMatrixSet[matrixCount][row][col]){
                        currentMatch += 1
                    }else{
                        currentMatch -= 1.25
                    }
                }
            }
            if(currentMatch > highestMatch){
                highestMatch = currentMatch
                highestMatchCharacter = key.key
            }
            currentMatch = 0
        }
    }
    
    return (highestMatchCharacter, highestMatch)
}
/*Add to the learned set of charactrs*/
func setLearnedCharacter(character c:String, matrix m:[[UInt8]]){
    if let _ = learnedSet[c] {
        learnedSet[c]?.append(m)
    }else{
        learnedSet[c] = [m]
    }
}
/*setter for adding correct character matrices to learned set*/
func learn(correctString s:String){
    /*Find the minimun count that can be learned without ambiguity*/
    let maxRecognizeCharacterCount:Int = min(correctMatrices.count, s.count)
    var i = 0
    for character in s {
        if(i == maxRecognizeCharacterCount){
            break
        }
        setLearnedCharacter(character: String(character), matrix: correctMatrices[i])
        i += 1
    }
    correctMatrices.removeAll()
}



