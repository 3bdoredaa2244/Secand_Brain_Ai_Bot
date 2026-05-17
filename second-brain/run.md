10. Daily workflow

Every day:

Terminal 1
cd E:\work\cloude\second-brain
docker-compose up redis chromadb -d


Terminal 2
cd E:\work\cloude\second-brain\backend
py -m uvicorn main:app --reload


Terminal 3
cd E:\work\cloude\second-brain\frontend
npm run dev

Then open:

http://localhost:3000
11. If backend fails

Run:

cd E:\work\cloude\second-brain
py verify_system.py

This checks: