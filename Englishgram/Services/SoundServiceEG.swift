import AVFoundation

@MainActor
final class SoundServiceEG {
    private let playback = SoundPlaybackEG()

    func play(success: Bool) {
        Task { [playback] in
            await playback.play(success: success)
        }
    }
}

private actor SoundPlaybackEG {
    private var player: AVAudioPlayer?
    private var sessionConfigured = false

    func play(success: Bool) {
        let rate = 22_050
        let length = success ? 0.16 : 0.12
        let count = Int(Double(rate) * length)
        let frequency = success ? 660.0 : 220.0
        var samples = Data()
        for index in 0..<count {
            let time = Double(index) / Double(rate)
            let envelope = sin(.pi * Double(index) / Double(count))
            var value = Int16(sin(time * frequency * 2 * .pi) * envelope * 3_000).littleEndian
            withUnsafeBytes(of: &value) { samples.append(contentsOf: $0) }
        }
        var data = Data("RIFF".utf8)
        func append<T: FixedWidthInteger>(_ number: T) {
            var little = number.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        append(UInt32(36 + samples.count))
        data.append(Data("WAVEfmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(rate)); append(UInt32(rate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(Data("data".utf8)); append(UInt32(samples.count)); data.append(samples)
        do {
            if !sessionConfigured {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
                sessionConfigured = true
            }
            player = try AVAudioPlayer(data: data)
            player?.play()
        } catch { player = nil }
    }
}
