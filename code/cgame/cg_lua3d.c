#include "cg_local.h"

qboolean lock = qfalse;

int lua_torefdef(lua_State *L, int idx, refdef_t *refdef, qboolean a640) {
	float x,y,w,h;
	vec3_t	angles;

	luaL_checktype(L,idx,LUA_TTABLE);

	x = qlua_pullfloat(L,"x",qfalse,refdef->x);
	y = qlua_pullfloat(L,"y",qfalse,refdef->y);
	w = qlua_pullfloat(L,"width",qfalse,refdef->width);
	h = qlua_pullfloat(L,"height",qfalse,refdef->height);
	refdef->fov_x = qlua_pullfloat(L,"fov_x",qfalse,refdef->fov_x);
	refdef->fov_y = qlua_pullfloat(L,"fov_y",qfalse,refdef->fov_y);
	qlua_pullvector(L,"origin",refdef->vieworg,qfalse);
	qlua_pullvector(L,"angles",angles,qfalse);
	refdef->rdflags = qlua_pullint(L,"flags",qfalse,0);
	refdef->zFar = qlua_pullfloat(L,"zFar",qfalse,0);
	refdef->zNear = qlua_pullfloat(L,"zNear",qfalse,0);
	refdef->rt_index = qlua_pullint(L,"renderTarget",qfalse,0);
	refdef->renderTarget = qlua_pullboolean(L,"isRenderTarget",qfalse,qfalse);
	
	//if(angles[0] != 0 || angles[1] != 0 || angles[2] != 0) {
		AnglesToAxis(angles,refdef->viewaxis);
	//}

	if(w > 0 && h > 0) {
		if(a640) {
			CG_AdjustFrom640( &x, &y, &w, &h );
			refdef->x = x;
			refdef->y = y;
			refdef->width = w;
			refdef->height = h;
		}
		return 0;
	} else {
		lua_pushstring(L,"RefDef Failed\n");
		lua_error(L);
		return 1;
	}
}

int qlua_setrefdef(lua_State *L) {
	luaL_checktype(L,1,LUA_TTABLE);
	lua_torefdef(L,1,&cg.refdef,qfalse);
	return 0;
}

int qlua_renderscene(lua_State *L) {
	refdef_t		refdef;
	int top = lua_gettop(L);
	int error = 0;

	if(lock) {
		lua_pushstring(L,"RefDefs Locked Durring 3D hook.\n");
		lua_error(L);
		return 1;
	}

	//memset( &refdef, 0, sizeof( refdef ) );
	refdef.x = 0;
	refdef.y = 0;
	refdef.fov_x = 30;
	refdef.fov_y = 30;
	refdef.time = cg.time;
	refdef.rdflags = RDF_NOWORLDMODEL;
	AxisClear( refdef.viewaxis );

	error = lua_torefdef(L, 1, &refdef, qtrue);
	if(error == 1) {
		trap_R_ClearScene();
		//CG_Printf("Scene Failed\n");
	} else {
		trap_R_RenderScene( &refdef );
		//CG_Printf("Rendered Scene: %f, %f, %f, %f\n",refdef.x,refdef.y,refdef.width,refdef.height);
	}
	return error;
}

int qlua_addPacketEnts(lua_State *L) {
	qhandle_t customShader = 0;
	if(lua_type(L,1) == LUA_TNUMBER) customShader = lua_tointeger(L,1);
	CG_AddPacketEntities(customShader);
	CG_AddMarks();
	CG_AddParticles ();
	CG_AddLocalEntities();
	return 0;
}
int qlua_addMarks(lua_State *L) {
	CG_AddMarks();
	return 0;
}
int qlua_addLocalEnts(lua_State *L) {
	CG_AddParticles ();
	CG_AddLocalEntities();
	return 0;
}

int qlua_createscene(lua_State *L) {
	if(lock) {
		lua_pushstring(L,"RefDefs Locked Durring 3D hook.\n");
		lua_error(L);
		return 1;		
	}

	trap_R_ClearScene();
	return 0;
}

void qlua_pullst(lua_State *L, float v[2], int idx) {
	vec3_t tvec;
	qlua_pullvector_i(L,2,tvec,qtrue,idx);
	v[0] = tvec[0];
	v[1] = tvec[1];
}

void qlua_pullmodulate(lua_State *L, byte v[4], int idx) {
	//CG_Printf("Pulled Ints\n");
	v[0] = (byte) qlua_pullint_i(L,3,qtrue,0,idx);
	v[1] = (byte) qlua_pullint_i(L,4,qtrue,0,idx);
	v[2] = (byte) qlua_pullint_i(L,5,qtrue,0,idx);
	v[3] = (byte) qlua_pullint_i(L,6,qtrue,0,idx);
}

void qlua_readvert(lua_State *L, polyVert_t *vert, vec3_t offset) {
	int idx = lua_gettop(L);

	//CG_Printf("   Read vector\n");
	qlua_pullvector_i(L,1,vert->xyz,qtrue,idx);
	
	//CG_Printf("   Read st\n");
	qlua_pullst(L,vert->st,idx);

	//CG_Printf("   Read modulate\n");
	qlua_pullmodulate(L,vert->modulate,idx);

	VectorAdd(vert->xyz,offset,vert->xyz);

	/*CG_Printf("   Out: %f,%f,%f [%f,%f] %i,%i,%i,%i\n",
		vert->xyz[0],
		vert->xyz[1],
		vert->xyz[2],
		vert->st[0],
		vert->st[1],
		(int) vert->modulate[0],
		(int) vert->modulate[1],
		(int) vert->modulate[2],
		(int) vert->modulate[3]);

	CG_Printf("   Done\n");*/
}

int qlua_passpoly(lua_State *L) {
	int size = 0;
	int i = 0;
	qhandle_t shader = cgs.media.whiteShader;
	vec3_t offset;
	polyVert_t	verts[1024];

	luaL_checktype(L,1,LUA_TTABLE);

	if(lua_type(L,2) == LUA_TNUMBER) {
		shader = lua_tointeger(L,2);
	}

	if(lua_type(L,3) == LUA_TVECTOR) {
		lua_tovector(L,3,offset);
	}

	size = luaL_getn(L,1);
	if(size > 1024) return 0;

	for(i=0;i<size;i++) {
		lua_pushinteger(L,i+1);
		lua_gettable(L,1);
		
		//CG_Printf("Read Vert: %i\n",i+1);
		qlua_readvert(L,&verts[i],offset);
	}

	trap_R_AddPolyToScene( shader, size, verts );

	return 0;
}

int qlua_polyref(lua_State *L) {
	int size = 0;
	int i = 0;
	refEntity_t *ref;
	vec3_t	vzero;

	VectorClear(vzero);

	luaL_checktype(L,1,LUA_TTABLE);

	if(lua_type(L,2) == LUA_TUSERDATA) {
		ref = lua_torefentity(L,2);
	}

	size = luaL_getn(L,1);
	if(size > 1024) return 0;

	for(i=0;i<size;i++) {
		lua_pushinteger(L,i+1);
		lua_gettable(L,1);
		
		//CG_Printf("Read Vert: %i\n",i+1);
		qlua_readvert(L,&ref->verts[i],vzero);
	}

	ref->numVerts = size;

	return 0;
}

int qlua_dlight(lua_State *L) {
	vec3_t pos;
	vec4_t color;
	float v = 0;

	luaL_checktype(L,1,LUA_TVECTOR);
	lua_tovector(L,1,pos);
	qlua_toColor(L,2,color,qfalse);
	v = lua_tonumber(L,5);
	trap_R_AddLightToScene( pos, v, color[0], color[1], color[2] );
	
	return 0;
}

int qlua_modelbounds(lua_State *L) {
	vec3_t	mins, maxs;

	luaL_checkint(L,1);

	trap_R_ModelBounds( lua_tointeger(L,1), mins, maxs );

	lua_pushvector(L,mins);
	lua_pushvector(L,maxs);
	return 2;
}

int qlua_setuprt(lua_State *L) {
	int index,width,height;
	index = luaL_checkint(L,1);
	width = luaL_checkint(L,2);
	height = luaL_checkint(L,3);

	trap_R_SetupRenderTarget(index,width,height);

	lua_pushinteger(L,index);
	return 1;
}

void RenderQuad(qhandle_t shader, vec3_t v1, vec3_t v2, vec3_t v3, vec3_t v4, vec4_t color, float s1, float t1, float s2, float t2) {
	polyVert_t	verts[4];
	verts[0].st[0] = s1;
	verts[0].st[1] = t1;
	verts[0].modulate[0] = (byte) (color[0] * 255);
	verts[0].modulate[1] = (byte) (color[1] * 255);
	verts[0].modulate[2] = (byte) (color[2] * 255);
	verts[0].modulate[3] = (byte) (color[3] * 255);
	VectorCopy(v1,verts[0].xyz);

	verts[1].st[0] = s2;
	verts[1].st[1] = t1;
	verts[1].modulate[0] = (byte) (color[0] * 255);
	verts[1].modulate[1] = (byte) (color[1] * 255);
	verts[1].modulate[2] = (byte) (color[2] * 255);
	verts[1].modulate[3] = (byte) (color[3] * 255);
	VectorCopy(v2,verts[1].xyz);

	verts[2].st[0] = s2;
	verts[2].st[1] = t2;
	verts[2].modulate[0] = (byte) (color[0] * 255);
	verts[2].modulate[1] = (byte) (color[1] * 255);
	verts[2].modulate[2] = (byte) (color[2] * 255);
	verts[2].modulate[3] = (byte) (color[3] * 255);
	VectorCopy(v3,verts[2].xyz);

	verts[3].st[0] = s1;
	verts[3].st[1] = t2;
	verts[3].modulate[0] = (byte) (color[0] * 255);
	verts[3].modulate[1] = (byte) (color[1] * 255);
	verts[3].modulate[2] = (byte) (color[2] * 255);
	verts[3].modulate[3] = (byte) (color[3] * 255);
	VectorCopy(v4,verts[3].xyz);

	trap_R_AddPolyToScene( shader, 4, verts );
}

int qlua_3Dquad(lua_State *L) {
	//float s,t,s2,t2;
	vec3_t v1,v2,v3,v4;
	vec4_t color;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TVECTOR);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);
	luaL_checktype(L,4,LUA_TVECTOR);

	lua_tovector(L,1,v1);
	lua_tovector(L,2,v2);
	lua_tovector(L,3,v3);
	lua_tovector(L,4,v4);

	if(lua_type(L,5) == LUA_TNUMBER) {
		shader = lua_tointeger(L,5);
	}

	qlua_toColor(L,6,color,qfalse);
	
	//s = quickfloat(L,6,0);
	//t = quickfloat(L,7,0);
	//s2 = quickfloat(L,8,1);
	//t2 = quickfloat(L,9,1);

	RenderQuad(shader,v1,v2,v3,v4,color,0,0,1,1);

	return 0;
}

static const luaL_reg Render_methods[] = {
  {"CreateScene",		qlua_createscene},
  {"DLight",			qlua_dlight},
  {"RenderScene",		qlua_renderscene},
  {"ModelBounds",		qlua_modelbounds},
  {"SetRefDef",			qlua_setrefdef},
  {"DrawPoly",			qlua_passpoly},
  {"PolyRef",			qlua_polyref},
  {"AddPacketEntities",	qlua_addPacketEnts},
  {"AddMarks",			qlua_addMarks},
  {"AddLocalEntities",	qlua_addLocalEnts},
  {"SetupRenderTarget",	qlua_setuprt},
  {"Quad",				qlua_3Dquad},
  {0,0}
};

int qlua_loadmodel(lua_State *L) {
	const char *model;

	if(lua_type(L,1) == LUA_TSTRING) {
		model = lua_tostring(L,1);
		lua_pushinteger(L,trap_R_RegisterModel( model ));
		return 1;
	}
	return 0;
}

void CG_InitLua3D(lua_State *L) {
	luaL_openlib(L, "render", Render_methods, 0);
	lua_register(L, "__loadmodel", qlua_loadmodel);
}

void CG_Lock3D(qboolean b) {
	lock = b;
}