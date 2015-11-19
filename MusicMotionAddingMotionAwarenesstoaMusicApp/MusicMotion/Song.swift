/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This class represents an instance of a single song.
*/

import Foundation
import UIKit

/**
    This struct is responsible for the storing the song metadata. The `SongManager`
    manages instances of this struct.
*/
struct Song: CustomDebugStringConvertible {
    // MARK: Properties

    var artist: String
    var title: String

    var albumImage: UIImage?

    // MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "Artist: \(artist), Title: \(title), Album Image: \(albumImage)"
    }
}
