"""Use the packaged DOCX rasterizer with a PDF exported by Microsoft Word.

The Windows runtime has no bundled LibreOffice. Word performs the layout;
the unchanged packaged renderer handles DPI, Poppler and page PNG naming.
"""
import importlib.util
from pathlib import Path
import shutil
import sys
import tempfile

scratch = Path(__file__).resolve().parent / 'renderer-temp'
scratch.mkdir(exist_ok=True)
tempfile.tempdir = str(scratch)

skill = Path(r'C:/Users/user/.codex/plugins/cache/openai-primary-runtime/documents/26.1112.11217/skills/documents')
spec = importlib.util.spec_from_file_location('packaged_render_docx', skill / 'render_docx.py')
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)
pdf = Path(sys.argv.pop(2)).resolve()

def from_word(doc_path, user_profile, convert_tmp_dir, stem, verbose):
    target = Path(convert_tmp_dir) / f'{stem}.pdf'
    shutil.copy2(pdf, target)
    return str(target), f'Layout exported by Microsoft Word: {pdf}'

renderer.convert_to_pdf = from_word
renderer.main()
