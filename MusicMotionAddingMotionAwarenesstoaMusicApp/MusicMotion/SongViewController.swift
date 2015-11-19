/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This class manages the presentation of the queued songs and updates when the users context changes.
*/

import UIKit

class SongViewController: UIViewController, UITableViewDelegate, SongManagerDelegate {
    // MARK: Properties

    static let textCellIdentifier = "SongCell"

    @IBOutlet weak var songTableView: UITableView!
    @IBOutlet weak var albumView: UIImageView!

    let motionManager = MotionManager()
    let songManager = SongManager()
    var cachedSongQueue = [Song]()

    // MARK: View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()

        motionManager.delegate = songManager

        /*
            This is currently needed to allow the Motion Activity Access dialog
            to appear in front of the app, instead of behind it.
        */
        dispatch_async(dispatch_get_main_queue()) {
            self.motionManager.startMonitoring()
        }

        songManager.delegate = self

        // Save the inital queue to present to the user.
        cachedSongQueue = songManager.songQueue

        updateAlbumViewWithSong(nil)

        selectFirstRow()
    }

    func updateAlbumViewWithSong(song: Song?) {
        // If no song is passed in, just use the first song in the queue.
        guard let song = song ?? cachedSongQueue.first else { return }

        albumView.image = song.albumImage
    }
    
    func selectFirstRow() {
        let rowToSelect = NSIndexPath(forRow: 0, inSection: 0)

        songTableView.selectRowAtIndexPath(rowToSelect, animated: false, scrollPosition: .None)

        tableView(songTableView, didSelectRowAtIndexPath: rowToSelect)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cachedSongQueue.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SongViewController.textCellIdentifier, forIndexPath: indexPath)

        let song = cachedSongQueue[indexPath.row]

        cell.textLabel!.text = song.artist
        cell.detailTextLabel!.text = song.title

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Create the header based on the intensity. For example "Low Intensity Music".
        return songManager.contextDescription
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let song = cachedSongQueue[indexPath.row]

        updateAlbumViewWithSong(song)
    }

    // MARK: SongManagerDelegate

    func didUpdateSongQueue(manager: SongManager) {
        let indexSet = NSIndexSet(index: 0)

        // Cache the songs to avoid modifications to the data outside the view controller.
        cachedSongQueue = manager.songQueue

        dispatch_async(dispatch_get_main_queue()) {
            self.songTableView.reloadSections(indexSet, withRowAnimation: .Fade)

            self.updateAlbumViewWithSong(nil)

            self.selectFirstRow()
        }
    }

    func didEncounterAuthorizationError(manager: SongManager) {
        let title = NSLocalizedString("Motion Activity Not Authorized", comment: "")

        let message = NSLocalizedString("To enable Motion features, please allow access to Motion & Fitness in Settings under Privacy.", comment: "")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)

        let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) { _ in
            // Open the Settings app.
            let url = NSURL(string: UIApplicationOpenSettingsURLString)!

            UIApplication.sharedApplication().openURL(url)
        }

        alert.addAction(openSettingsAction)

        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion:nil)
        }
    }
}
