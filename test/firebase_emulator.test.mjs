import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, sendPasswordResetEmail } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, doc, setDoc, updateDoc, deleteDoc, getDoc, getDocs, collection, serverTimestamp, Timestamp, onSnapshot, disableNetwork, enableNetwork, terminate } from 'firebase/firestore';

let env;
const apps = [];
const projectId = 'demo-enfoque';
const stamp = () => serverTimestamp();
function task(overrides = {}) { return {title:'Entregar proyecto académico',description:'Revisar informe',categoryId:'estudios',dueAt:Timestamp.fromDate(new Date(Date.now()+3600000)),priority:2,completed:false,reminder:true,createdAt:stamp(),updatedAt:stamp(),...overrides}; }
function waitFor(ref, predicate) {
  return new Promise((resolve,reject) => {
    const timer = setTimeout(() => { stop(); reject(new Error('No llegó el cambio en 10 s')); },10000);
    const stop = onSnapshot(ref, {includeMetadataChanges:true}, s => {
      if (predicate(s)) { clearTimeout(timer); stop(); resolve(s); }
    }, e => { clearTimeout(timer); reject(e); });
  });
}
before(async () => {
  env = await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8080,rules:await readFile('firestore.rules','utf8')}});
  await env.clearFirestore();
});
after(async () => {
  for (const a of apps) { await terminate(getFirestore(a)); await deleteApp(a); }
  await env.cleanup();
});

test('reglas: propietario crea, edita, completa y elimina una tarea',async () => {
  const db = env.authenticatedContext('alumno-a').firestore();
  const ref = doc(db,'users/alumno-a/tasks/crud');
  await assertSucceeds(setDoc(ref,task()));
  await assertSucceeds(updateDoc(ref,{title:'Proyecto revisado',updatedAt:stamp()}));
  await assertSucceeds(updateDoc(ref,{completed:true,updatedAt:stamp()}));
  assert.equal((await getDoc(ref)).data().completed,true);
  await assertSucceeds(deleteDoc(ref));
  assert.equal((await getDoc(ref)).exists(),false);
});
test('reglas: otro usuario no puede leer, listar, crear, editar ni borrar datos ajenos',async () => {
  const own = env.authenticatedContext('alumno-a').firestore();
  await setDoc(doc(own,'users/alumno-a/tasks/privada'),task());
  const other = env.authenticatedContext('alumno-b').firestore();
  const ref = doc(other,'users/alumno-a/tasks/privada');
  await assertFails(getDoc(ref));
  await assertFails(getDocs(collection(other,'users/alumno-a/tasks')));
  await assertFails(setDoc(doc(other,'users/alumno-a/tasks/intrusa'),task()));
  await assertFails(updateDoc(ref,{title:'Intrusión',updatedAt:stamp()}));
  await assertFails(deleteDoc(ref));
  await assertFails(getDoc(doc(other,'users/alumno-a/preferences/interface')));
  await assertFails(getDocs(collection(other,'users/alumno-a/categories')));
});
test('reglas: usuario anónimo y rutas desconocidas denegados',async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db,'users/alumno-a/tasks/x'),task()));
  await assertFails(getDoc(doc(db,'users/alumno-a/tasks/privada')));
  await assertFails(setDoc(doc(env.authenticatedContext('a').firestore(),'public/x'),{open:true}));
});
test('reglas: rechaza títulos vacíos, tipos, campos extra y auditoría falsificada',async () => {
  const db = env.authenticatedContext('validacion').firestore();
  for (const bad of [{title:''},{title:'   '},{priority:7},{completed:'sí'},{reminder:true,dueAt:null},{secret:'extra'},{title:'a'.repeat(121)},{createdAt:Timestamp.fromMillis(1)},{updatedAt:Timestamp.fromMillis(1)}]) {
    await assertFails(setDoc(doc(db,'users/validacion/tasks/x'),task(bad)));
  }
  const ref = doc(db,'users/validacion/tasks/immutable');
  await setDoc(ref,task());
  await assertFails(updateDoc(ref,{createdAt:stamp(),updatedAt:stamp()}));
});
test('categorías: archivar conserva tareas y se impide borrado físico',async () => {
  const db = env.authenticatedContext('categorias').firestore();
  const category = doc(db,'users/categorias/categories/estudios');
  const ref = doc(db,'users/categorias/tasks/exposicion');
  await setDoc(category,{name:'Estudios',archived:false,updatedAt:stamp()});
  await setDoc(ref,task());
  await updateDoc(category,{name:'Instituto',updatedAt:stamp()});
  await updateDoc(category,{archived:true,updatedAt:stamp()});
  assert.equal((await getDoc(ref)).data().categoryId,'estudios');
  await assertFails(deleteDoc(category));
  await assertFails(setDoc(category,{name:'',archived:false,updatedAt:stamp()}));
});
test('preferencias: persisten y solo admiten esquema autorizado',async () => {
  const db = env.authenticatedContext('preferencias').firestore();
  const ref = doc(db,'users/preferencias/preferences/interface');
  await setDoc(ref,{dark:true,accent:1,notifications:false});
  assert.equal((await getDoc(ref)).data().dark,true);
  await assertFails(updateDoc(ref,{accent:3}));
  await assertFails(updateDoc(ref,{admin:true}));
});
test('integración Auth y Firestore: registro, dos sesiones, sincronización, caché y reconexión', {timeout:60000},async () => {
  const email = `sesion-${Date.now()}@enfoque.test`;
  function session(name) {
    const app = initializeApp({projectId,apiKey:'demo-api-key',appId:`demo-${name}`},name); apps.push(app);
    const auth = getAuth(app); connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});
    const db = getFirestore(app); connectFirestoreEmulator(db,'127.0.0.1',8080);
    return {auth,db};
  }
  const a = session('A'), b = session('B');
  const cred = await createUserWithEmailAndPassword(a.auth,email,'Proyecto123!');
  await signInWithEmailAndPassword(b.auth,email,'Proyecto123!');
  assert.equal(b.auth.currentUser.uid,cred.user.uid);
  const path = `users/${cred.user.uid}/tasks/sincronizada`;
  const ra = doc(a.db,path), rb = doc(b.db,path);
  const created = waitFor(rb,s => s.exists());
  await setDoc(ra,task()); await created;
  const edited = waitFor(rb,s => s.data()?.title === 'Cambio desde A');
  await updateDoc(ra,{title:'Cambio desde A',updatedAt:stamp()}); await edited;
  const completed = waitFor(ra,s => s.data()?.completed === true);
  await updateDoc(rb,{completed:true,updatedAt:stamp()}); await completed;
  await disableNetwork(a.db);
  const pending = waitFor(ra,s => s.metadata.hasPendingWrites && s.data()?.title === 'Cambio sin conexión');
  const queuedWrite = updateDoc(ra,{title:'Cambio sin conexión',updatedAt:stamp()});
  await pending;
  const reconnected = waitFor(rb,s => s.data()?.title === 'Cambio sin conexión');
  await enableNetwork(a.db); await queuedWrite; await reconnected;
  await signOut(b.auth);
  await assert.rejects(signInWithEmailAndPassword(b.auth,email,'incorrecta'));
  await signInWithEmailAndPassword(b.auth,email,'Proyecto123!');
  assert.equal((await getDoc(rb)).data().title,'Cambio sin conexión');
  await sendPasswordResetEmail(a.auth,email);
  const removed = waitFor(rb,s => !s.exists());
  await deleteDoc(ra); await removed;
  await signOut(a.auth); await signOut(b.auth);
});
