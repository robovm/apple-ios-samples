/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains a `SongManager` and `SongManagerDelegate` protocol that allows for managing a song playback queue.
*/

import Foundation
import UIKit

/// A protocol to allow `SongManager` object delegate's to be notified of changes.
protocol SongManagerDelegate: class {
    func didUpdateSongQueue(manager: SongManager)
    func didEncounterAuthorizationError(manager: SongManager)
}

/**
    This class manages the song playback queue. This class also provides a delegate 
    to inform the UI when the queue has updated in response to the users motion
    context.
*/
class SongManager: MotionContextDelegate {
    // MARK: Properties

    weak var delegate: SongManagerDelegate?

    var songQueue = [Song]()

    var currentContext = MotionContext.LowIntensity

    var contextDescription: String {
        return currentContext.description + " Music"
    }

    // MARK: Initialization

    init() {
        queueLowIntensitySongs()
    }

    // MARK: Other Methods

    func queueLowIntensitySongs() {
       currentContext = .LowIntensity
        
        songQueue = [
            Song(artist: "Haunting Irish female singer", title: "Something by a haunting Irish female singer", albumImage: UIImage(named: "Iceland_016")),
            
            Song(artist: "Some 70's British rock band", title: "That Champion Song", albumImage: UIImage(named: "Italy_008")),
            
            Song(artist: "An upbeat electronic artist", title: "Another song that validates me", albumImage: UIImage(named: "Iceland_005"))
        ]
    }

    func queueMediumIntensitySongs() {
        currentContext = .MediumIntensity

        songQueue = [
            Song(artist: "Hippie Artist", title: "New age music", albumImage: UIImage(named: "Italy_017")),
            
            Song(artist: "Another Hippie Artist", title: "More new age music", albumImage: UIImage(named: "Iceland_017")),
            
            Song(artist: "Electronic Artist", title: "Tune from that fire chariots movie", albumImage: UIImage(named: "Iceland_006"))
        ]
    }

    func queueHighIntensitySongs() {
        currentContext = .HighIntensity

        songQueue = [
            Song(artist: "That self-serious goth band", title: "Song that begins slowly and builds", albumImage: UIImage(named: "Iceland_001")),
            
            Song(artist: "A 90's rock band", title: "Catchy 120 beats-per-min rock song", albumImage: UIImage(named: "Iceland_018")),
            
            Song(artist: "A roller disco band", title: "Uptempo disco track", albumImage: UIImage(named: "Italy_019"))
        ]
    }

    func queueDrivingSongs() {
        currentContext = .Driving

        songQueue = [
            Song(artist: "Burning Rubber", title: "Smells Great", albumImage: UIImage(named: "Lola_006")),
            
            Song(artist: "Sunny's Podcast", title: "In May", albumImage: UIImage(named: "Lola_009")),
            
            Song(artist: "Drive Time", title: "So Much Traffic", albumImage: UIImage(named: "Lola_011"))
        ]
    }

    // MARK: MotionContextDelegate

    func lowIntensityContextStarted(manager: MotionManager) {
        queueLowIntensitySongs()
        delegate?.didUpdateSongQueue(self)
    }

    func mediumIntensityContextStarted(manager: MotionManager) {
        queueMediumIntensitySongs()
        delegate?.didUpdateSongQueue(self)
    }

    func highIntensityContextStarted(manager: MotionManager) {
        queueHighIntensitySongs()
        delegate?.didUpdateSongQueue(self)
    }

    func drivingContextStarted(manager: MotionManager) {
        queueDrivingSongs()
        delegate?.didUpdateSongQueue(self)
    }

    func didEncounterAuthorizationError(manager: MotionManager) {
        delegate?.didEncounterAuthorizationError(self)
    }
}
