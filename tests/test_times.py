import os
import unittest
import sys

sys.path[:0] = [os.path.abspath(os.path.join(__file__, '..', '..'))]
import times


class TestTimes(unittest.TestCase):
    nightly_lines = [
        '01-02 03:04:05.000  1784  7719 I WindowManager: Hello there',
        ('01-02 03:04:06.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: +941ms'),
        '01-02 03:04:07.000  1784  7719 I ActivityManager: This is a message',
        ('01-02 03:04:08.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: +1s41ms '
         '(total 1s529ms)'),
    ]

    performance_lines = [
        '01-02 03:04:05.000  1784  7719 I WindowManager: Hello there',
        ('01-02 03:04:06.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: '
         '+941ms'),
        '01-02 03:04:07.000  1784  7719 I ActivityManager: This is a message',
        ('01-02 03:04:08.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: '
         '+1s41ms (total 1s529ms)'),
    ]

    fennec_lines = [
        '01-02 03:04:05.000  1784  7719 I WindowManager: Hello there',
        ('01-02 03:04:06.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.firefox/org.mozilla.gecko.BrowserApp: +941ms'),
        '01-02 03:04:07.000  1784  7719 I ActivityManager: This is a message',
        ('01-02 03:04:08.000  1784  7719 I ActivityManager: Fully drawn '
         'org.mozilla.firefox/org.mozilla.gecko.BrowserApp: +1s41ms '
         '(total 1s529ms)'),
    ]

    def test_match_fenix_nightly(self):
        result = times.Runtime.find_displayed_lines('fenix-nightly',
                                                    self.nightly_lines)
        self.assertEqual(result, [
            self.nightly_lines[1], self.nightly_lines[3]
        ])

    def test_match_fenix_performance(self):
        result = times.Runtime.find_displayed_lines('fenix-performance',
                                                    self.performance_lines)
        self.assertEqual(result, [
            self.performance_lines[1], self.performance_lines[3]
        ])

    def test_match_fennec(self):
        result = times.Runtime.find_displayed_lines('fennec',
                                                    self.fennec_lines)
        self.assertEqual(result, [
            self.fennec_lines[1], self.fennec_lines[3]
        ])

    def test_convert_fenix_nightly(self):
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.nightly_lines[1], 'fenix-nightly'
        ), 0.941)
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.nightly_lines[3], 'fenix-nightly'
        ), 1.041)
        with self.assertRaises(ValueError):
            times.Runtime.convert_displayed_line_to_time(
                self.nightly_lines[0], 'fenix-nightly'
            )

    def test_convert_fenix_performance(self):
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.performance_lines[1], 'fenix-performance'
        ), 0.941)
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.performance_lines[3], 'fenix-performance'
        ), 1.041)
        with self.assertRaises(ValueError):
            times.Runtime.convert_displayed_line_to_time(
                self.performance_lines[0], 'fenix-performance'
            )

    def test_convert_fennec(self):
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.fennec_lines[1], 'fennec'
        ), 0.941)
        self.assertEqual(times.Runtime.convert_displayed_line_to_time(
            self.fennec_lines[3], 'fennec'
        ), 1.041)
        with self.assertRaises(ValueError):
            times.Runtime.convert_displayed_line_to_time(
                self.fennec_lines[0], 'fennec'
            )


if __name__ == '__main__':
    unittest.main()
