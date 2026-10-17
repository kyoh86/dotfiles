import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import pick_services


class CandidatesTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.TemporaryDirectory()
        self.addCleanup(self.root.cleanup)
        self.env = patch.dict(os.environ, {"XDG_STATE_HOME": self.root.name})
        self.env.start()
        self.addCleanup(self.env.stop)

    def credentials(self, path, text):
        target = Path(self.root.name) / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def test_inkdrop_paginates_and_does_not_return_credentials(self):
        self.credentials(
            "denops-inkdrop/credentials.toml",
            'baseUrl="http://127.0.0.1:19840"\nusername="test-user"\npassword="test-password"\n',
        )
        first = [{"_id": str(i), "title": "note"} for i in range(100)]
        with patch.object(pick_services, "request", side_effect=[first, [{"_id": "last"}]]) as req:
            notes = pick_services.candidates("inkdrop", "notes", "unused")
        self.assertEqual(len(notes), 101)
        self.assertEqual(req.call_args_list[1].args[3]["skip"], 100)
        self.assertTrue(req.call_args_list[0].args[2]["Authorization"].startswith("Basic "))
        self.assertNotIn("test-password", json.dumps(notes))

    def test_docbase_templates_follow_pages(self):
        self.credentials("denops-docbase/teams/example.toml", 'token="test-token"\n')
        with patch.object(pick_services, "request", side_effect=[
            {"posts": [{"id": 1}], "meta": {"next_page": "next"}},
            {"posts": [{"id": 2}], "meta": {"next_page": None}},
        ]) as req:
            posts = pick_services.candidates("docbase", "templates", "example")
        self.assertEqual([post["id"] for post in posts], [1, 2])
        self.assertEqual(req.call_args_list[0].args[3]["q"], "tag:template")
        self.assertEqual(req.call_args_list[1].args[3]["page"], 2)

    def test_errors_do_not_expose_service_details(self):
        output, errors = io.StringIO(), io.StringIO()
        with patch("sys.argv", ["pick_services.py", "inkdrop", "notes"]):
            with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
                status = pick_services.main()
        self.assertEqual(status, 1)
        self.assertEqual(output.getvalue(), "")
        self.assertIn(":InkdropLogin", errors.getvalue())
        self.assertNotIn(self.root.name, errors.getvalue())


if __name__ == "__main__":
    unittest.main()
