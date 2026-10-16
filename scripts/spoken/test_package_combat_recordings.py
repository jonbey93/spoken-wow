import importlib.util
from pathlib import Path
import tempfile
import unittest
import wave
import zipfile


spec = importlib.util.spec_from_file_location("package_combat", Path(__file__).with_name("package-combat-recordings.py"))
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)


class RecordingPackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "recordings"
        self.source.mkdir()
        self.output = self.root / "out.zip"
        for number in range(1, 9):
            self.wav(self.source / f"{number:02d}.wav")

    def wav(self, path, seconds=1):
        with wave.open(str(path), "wb") as recording:
            recording.setparams((1, 2, 22050, 0, "NONE", "not compressed"))
            recording.writeframes(b"\0\0" * int(22050 * seconds))

    def test_complete_set_preserves_audio_and_measures_manifest(self):
        packager.package_recordings(self.source, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertIsNone(archive.testzip())
            self.assertEqual(len(archive.namelist()), 10)
            self.assertEqual({name.split("/")[0] for name in archive.namelist()}, {"SpokenCombatAudio"})
            self.assertIn("Data/Sounds.lua", archive.read("SpokenCombatAudio/SpokenCombatAudio.toc").decode())
            self.assertIn('length = 1.000, format = "wav"', archive.read("SpokenCombatAudio/Data/Sounds.lua").decode())
            self.assertEqual(archive.read("SpokenCombatAudio/Sounds/Combat/nightelf-female-standard-01.wav"),
                             (self.source / "01.wav").read_bytes())

    def test_missing_recordings_do_not_replace_existing_output(self):
        (self.source / "08.wav").unlink()
        self.output.write_bytes(b"keep existing package")
        with self.assertRaisesRegex(ValueError, "Missing recordings: 08"):
            packager.package_recordings(self.source, self.output)
        self.assertEqual(self.output.read_bytes(), b"keep existing package")

    def test_duplicate_key_is_rejected(self):
        self.wav(self.source / "nightelf-female-standard-01.wav")
        with self.assertRaisesRegex(ValueError, "More than one"):
            packager.package_recordings(self.source, self.output)

    def test_extra_audio_is_rejected(self):
        self.wav(self.source / "09.wav")
        with self.assertRaisesRegex(ValueError, "Unexpected recording"):
            packager.package_recordings(self.source, self.output)

    def test_long_audio_is_rejected(self):
        self.wav(self.source / "01.wav", seconds=7)
        with self.assertRaisesRegex(ValueError, "6-second limit"):
            packager.package_recordings(self.source, self.output)

    def test_compressed_input_requires_a_duration_reader(self):
        with self.assertRaisesRegex(ValueError, "ffprobe is required"):
            packager.duration_of(self.source / "01.mp3", None)

    def test_output_cannot_overwrite_a_supplied_recording(self):
        file = self.source / "01.wav"
        original = file.read_bytes()
        with self.assertRaisesRegex(ValueError, "must not replace"):
            packager.package_recordings(self.source, file)
        self.assertEqual(file.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
